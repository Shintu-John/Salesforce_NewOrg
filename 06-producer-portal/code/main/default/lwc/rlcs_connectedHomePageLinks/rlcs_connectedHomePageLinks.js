import { LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getUpcomingDates from '@salesforce/apex/rlcs_connectedHomePageLinks.getUpcomingDates';
import getPastDue from '@salesforce/apex/rlcs_connectedHomePageLinks.getPastDue';
import getCurrentUserAccountInfo from '@salesforce/apex/rlcs_connectedHomePageLinks.getCurrentUserAccountInfo';
import USER_ID from '@salesforce/user/Id';
import IMAGES from './constants';

export default class Rlcs_connectedHomePageLinks extends LightningElement {
    upcomingDates = [];
    get isUpcomingDatesAvailable(){return this.upcomingDates.length > 0;}

    pastDues = [];
    get isPastDuesAvaialble(){return this.pastDues.length > 0;}

    @track showGrabButton = false;
    @track menuItems = [];
    @track subMenuItems = [];
    @track accountInfo = null;

    @track containerStyle = {};
    @track mainMenuImageStyle = {};
    @track subMenuItemStyle = {};
    initialLoadComplete = false;

    domCache = {
        container: null,
        menuItems: null,
        subMenuItems: null
    };

    @wire(getRecord, {
        recordId: USER_ID,
        fields: ['User.Contact.AccountId']
    })
    wiredUser({ error, data }) {
        if (data) {
            const accountId = data.fields.Contact.value?.fields?.AccountId?.value;
            this.showGrabButton = accountId === '0014H00002QCOgYQAX';
            if (!this.initialLoadComplete) {
                this.initializeMenuItems();
                this.initialLoadComplete = true;
            }
        } else if (error) {
            console.error('Error loading user data:', error);
            if (!this.initialLoadComplete) {
                this.initializeMenuItems();
                this.initialLoadComplete = true;
            }
        }
    }

    connectedCallback() {
        this.setupDynamicResizing();
    }

    @wire(getUpcomingDates)
    wiredData_getUpcomingDates({ error, data }) {
      if (data) {
         this.upcomingDates = data;
      } else if (error) {
        console.error('Error:', error);
      }
    }

    @wire(getPastDue)
    wiredData_getPastDue({ error, data }) {
      if (data) {
         this.pastDues = data;
      } else if (error) {
        console.error('Error:', error);
      }
    }

    @wire(getCurrentUserAccountInfo)
    wiredAccountInfo({ error, data }) {
        if (data) {
            this.accountInfo = data;
            this.initializeSubMenuItems();
        } else if (error) {
            console.error('Error loading account info:', error);
            this.initializeSubMenuItems();
        }
    }

    redirectToRecord(event){
        window.location = '/RLCS/' + event.currentTarget.dataset.id;
    }

    renderedCallback() {
        this.cacheDOMElements();
        this.setupSubMenuItemStyles();
        this.updateStyles();
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.handleResize);
    }

    initializeMenuItems() {
        const menuItems = [{
            label: 'Upcoming Dates',
            url: '/RLCS/s/producer-placed-on-market/Producer_Placed_on_Market__c/Default',
            image: IMAGES.MENU.UPCOMMING_DATES.DEFAULT,
            hoverImage: IMAGES.MENU.UPCOMMING_DATES.HOVER,
            iconName : 'utility:field_date_calc'
        }];
        
        menuItems.push({
            label: 'Past Due',
            url: '/RLCS/s/producer-placed-on-market/Producer_Placed_on_Market__c/Default?tabset-dbea4=2',
            image: IMAGES.MENU.DUE_DATES.DEFAULT,
            hoverImage: IMAGES.MENU.DUE_DATES.HOVER,
            iconName: 'utility:field_date_time_calc'
        });
        
        this.menuItems = menuItems;
        this.preloadImages();

        // Add spacing logic
        requestAnimationFrame(() => {
            const mainMenu = this.template.querySelector('.main-menu');
            if (mainMenu) {
                mainMenu.classList.toggle('three-buttons', menuItems.length === 3);
            }
        });
    }

    initializeSubMenuItems() {
        const baseItems = [
            {
                label: 'Dashboard',
                url: '/RLCS/s/dashboard',
                image: IMAGES.SUBMENU.DASHBOARD.DEFAULT,
                hoverImage: IMAGES.SUBMENU.DASHBOARD.HOVER
            },
            {
                label: 'Compliance Documents',
                url: '/RLCS/s/compliance-documentation',
                image: IMAGES.SUBMENU.COMPLIANCE_DOCS.DEFAULT,
                hoverImage: IMAGES.SUBMENU.COMPLIANCE_DOCS.HOVER
            }
        ];

        // Add Reports link only if account is not B2B
        if (this.accountInfo?.showReportsLink !== false) {
            baseItems.push({
                label: 'Reports',
                url: '/RLCS/s/reports',
                image: IMAGES.SUBMENU.REPORTS.DEFAULT,
                hoverImage: IMAGES.SUBMENU.REPORTS.HOVER
            });
        }

        baseItems.push({
            label: 'Invoices',
            url: '/RLCS/s/invoices',
            image: IMAGES.SUBMENU.INVOICES.DEFAULT,
            hoverImage: IMAGES.SUBMENU.INVOICES.HOVER
        });

        this.subMenuItems = baseItems;

        // Update CSS grid layout based on number of items
        requestAnimationFrame(() => {
            const subMenu = this.template.querySelector('.sub-menu');
            if (subMenu) {
                if (this.subMenuItems.length === 3) {
                    subMenu.style.gridTemplateColumns = 'repeat(3, 1fr)';
                    subMenu.style.gridTemplateRows = '1fr';
                } else {
                    subMenu.style.gridTemplateColumns = 'repeat(2, 1fr)';
                    subMenu.style.gridTemplateRows = 'repeat(2, auto)';
                }
            }
        });
    }

    preloadImages() {
        const allImages = [
            ...this.menuItems.map(item => [item.image, item.hoverImage]),
            ...this.subMenuItems.map(item => [item.image, item.hoverImage])
        ].flat();

        allImages.forEach(src => {
            if (src) {
                const img = new Image();
                img.src = src;
            }
        });
    }

    cacheDOMElements() {
        this.domCache.container = this.template.querySelector('.rls-navigation-wrapper');
        this.domCache.menuItems = this.template.querySelectorAll('.menu-item-image');
        this.domCache.subMenuItems = this.template.querySelectorAll('.sub-menu-item');
    }

    setupSubMenuItemStyles() {
        this.template.querySelectorAll('.sub-menu-item').forEach(item => {
            item.style.backgroundImage = `url(${item.dataset.image})`;
            item.addEventListener('mouseenter', this.handleSubMenuMouseEnter);
            item.addEventListener('mouseleave', this.handleSubMenuMouseLeave);
        });
    }

    setupDynamicResizing() {
        this.handleResize = this.handleResize.bind(this);
        window.addEventListener('resize', this.debounceResize.bind(this));
        this.handleResize();
    }

    debounceResize() {
        if (this.resizeTimeout) {
            window.clearTimeout(this.resizeTimeout);
        }
        this.resizeTimeout = window.setTimeout(() => {
            this.handleResize();
        }, 250);
    }

    handleResize() {
        const dpr = window.devicePixelRatio || 1;
        const baseHeight = 400;
        const adjustedHeight = Math.min(baseHeight, Math.round(baseHeight / dpr));

        this.containerStyle = {
            height: `${adjustedHeight}px`,
            maxHeight: `${adjustedHeight}px`,
            minHeight: `${adjustedHeight}px`
        };

        const sizeMultiplier = 2.05;
        const scaleFactor = (adjustedHeight / baseHeight) * sizeMultiplier;

        this.mainMenuImageStyle = {
            height: `${Math.round(50 * scaleFactor)}px`,
            width: 'auto'
        };

        this.subMenuItemStyle = {
            height: `${Math.round(70 * scaleFactor)}px`,
            width: 'auto',
            backgroundSize: 'auto 100%'
        };

        this.updateStyles();
    }

    updateStyles() {
        if (this.domCache.container) {
            Object.assign(this.domCache.container.style, this.containerStyle);
        }

        if (this.domCache.menuItems) {
            this.domCache.menuItems.forEach(item => {
                Object.assign(item.style, this.mainMenuImageStyle);
            });
        }

        if (this.domCache.subMenuItems) {
            this.domCache.subMenuItems.forEach(item => {
                Object.assign(item.style, this.subMenuItemStyle);
            });
        }
    }

    handleSubMenuMouseEnter(event) {
        event.target.style.backgroundImage = `url(${event.target.dataset.hoverimage})`;
    }

    handleSubMenuMouseLeave(event) {
        event.target.style.backgroundImage = `url(${event.target.dataset.image})`;
    }
}