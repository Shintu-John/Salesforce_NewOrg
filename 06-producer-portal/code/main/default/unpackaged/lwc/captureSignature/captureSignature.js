import { LightningElement,api } from 'lwc';
import saveSign from '@salesforce/apex/SignatureLwcHelper.saveSignature';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

let isDownFlag,
isDotFlag = false,
prevX = 0,
currX = 0,
prevY = 0,
currY = 0,
startX = 0,
startY = 0,
hasActualDrawing = false;

let x = "#0000A0"; //blue color
let y = 1.5; //weight of line width and dot.

let canvasElement, ctx; //storing canvas context
let dataURL,convertedDataURI; //holds image data

export default class CaptureSignature extends LightningElement {

    @api recordId;
    @api docIdField;
    docId;
    
    ContentVersionData;
    signatureMode = 'draw'; // 'draw' or 'upload'
    uploadedImageData = null;
    _hasSignature = false; // Private property to avoid reactivity
    _canvasInitialized = false; // Flag to prevent re-initialization

    isSpinner = false;
    //event listeners added for drawing the signature within shadow boundary
    constructor() {
        super();
        this.template.addEventListener('mousemove', this.handleMouseMove.bind(this));
        this.template.addEventListener('mousedown', this.handleMouseDown.bind(this));
        this.template.addEventListener('mouseup', this.handleMouseUp.bind(this));
        this.template.addEventListener('mouseout', this.handleMouseOut.bind(this));
    }

    //retrieve canvase and context
    renderedCallback(){
        const currentCanvas = this.template.querySelector('canvas');
        
        // Only initialize if we have a new canvas or haven't initialized yet
        if (currentCanvas && (!this._canvasInitialized || currentCanvas !== canvasElement)) {
            canvasElement = currentCanvas;
            ctx = canvasElement.getContext("2d");
            
            // Only set dimensions if canvas is new or uninitialized
            if (!this._canvasInitialized) {
                // Set canvas actual dimensions to match CSS dimensions for proper coordinate mapping
                const rect = canvasElement.getBoundingClientRect();
                canvasElement.width = rect.width;
                canvasElement.height = rect.height;
                this._canvasInitialized = true;
            }
        }
    }

    //handler for mouse move operation
    handleMouseMove(event){
        this.searchCoordinatesForEvent('move', event);
    }

    //handler for mouse down operation
    handleMouseDown(event){
        this.searchCoordinatesForEvent('down', event);
    }

    //handler for mouse up operation
    handleMouseUp(event){
        this.searchCoordinatesForEvent('up', event);
    }

    //handler for mouse out operation
    handleMouseOut(event){
        this.searchCoordinatesForEvent('out', event);
    }
    
    handleSaveClick(){
        //set to draw behind current content
        ctx.globalCompositeOperation = "destination-over";
        ctx.fillStyle = "#FFF"; //white
        ctx.fillRect(0,0,canvasElement.width, canvasElement.height);

        //convert to png image as dataURL
        dataURL = canvasElement.toDataURL("image/png");
        //convert that as base64 encoding
        convertedDataURI = dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
        this.ContentVersionData = convertedDataURI;
        //call Apex method imperatively and use promise for handling sucess & failure
        this.isSpinner = true;
        saveSign({
            ContentVersionData: convertedDataURI,
            recordId : this.recordId,
            docIdField : this.docIdField
        })
        .then(result => {
            this.docId = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Salesforce File created with Signature',
                    variant: 'success',
                }),
            );
            
            // Navigate to next step in flow after successful signature capture
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        })
        .catch(error => {
            console.log('error : ',error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating Salesforce File record',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        })
        .finally(() => {
            this.isSpinner = false;
        });
    }

    //clear the signature from canvas
    handleClearClick(){
        ctx.clearRect(0, 0, canvasElement.width, canvasElement.height);
        this.uploadedImageData = null;
        this._hasSignature = false;
        
        // Reset file input in upload mode
        if (this.signatureMode === 'upload') {
            const fileInput = this.template.querySelector('input[type="file"]');
            if (fileInput) {
                fileInput.value = '';
            }
        }
        
        // Reset signature status when clearing
        this._hasSignature = false;
        // Force button update
        this.updateButtonState();
    }

    // Toggle between draw and upload modes
    handleModeChange(event) {
        this.signatureMode = event.target.value;
        this.handleClearClick(); // Clear any existing signature when switching modes
        
        // Reset signature status after mode change
        this._hasSignature = false;
        // Reset canvas initialization to allow re-setup for new mode
        this._canvasInitialized = false;
    }

    // Handle file upload
    handleFileUpload(event) {
        const file = event.target.files[0];
        
        if (!file) return;

        // Validate file type
        const allowedTypes = ['image/png', 'image/jpeg', 'image/jpg'];
        if (!allowedTypes.includes(file.type)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid File Type',
                    message: 'Please upload only PNG or JPG files',
                    variant: 'error',
                }),
            );
            event.target.value = ''; // Clear the input
            return;
        }

        // Validate file size (max 5MB)
        const maxSize = 5 * 1024 * 1024; // 5MB in bytes
        if (file.size > maxSize) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'File Too Large',
                    message: 'Please upload an image smaller than 5MB',
                    variant: 'error',
                }),
            );
            event.target.value = '';
            return;
        }

        // Read and process the file
        const reader = new FileReader();
        reader.onload = (e) => {
            this.uploadedImageData = e.target.result;
            this.drawUploadedImageToCanvas();
        };
        reader.readAsDataURL(file);
    }

    // Draw uploaded image to canvas
    drawUploadedImageToCanvas() {
        const img = new Image();
        img.onload = () => {
            // Clear canvas
            ctx.clearRect(0, 0, canvasElement.width, canvasElement.height);
            
            // Calculate scaling to fit image within canvas while maintaining aspect ratio
            const canvasWidth = canvasElement.width;
            const canvasHeight = canvasElement.height;
            const imgAspectRatio = img.width / img.height;
            const canvasAspectRatio = canvasWidth / canvasHeight;
            
            let drawWidth, drawHeight, offsetX, offsetY;
            
            if (imgAspectRatio > canvasAspectRatio) {
                // Image is wider than canvas ratio
                drawWidth = canvasWidth;
                drawHeight = canvasWidth / imgAspectRatio;
                offsetX = 0;
                offsetY = (canvasHeight - drawHeight) / 2;
            } else {
                // Image is taller than canvas ratio
                drawWidth = canvasHeight * imgAspectRatio;
                drawHeight = canvasHeight;
                offsetX = (canvasWidth - drawWidth) / 2;
                offsetY = 0;
            }
            
            // Draw the image centered and scaled
            ctx.drawImage(img, offsetX, offsetY, drawWidth, drawHeight);
            this._hasSignature = true;
            // Force button update
            this.updateButtonState();
        };
        img.src = this.uploadedImageData;
    }

    // Getters for template
    get isDrawMode() {
        return this.signatureMode === 'draw';
    }

    get isUploadMode() {
        return this.signatureMode === 'upload';
    }

    get modeOptions() {
        return [
            { label: 'Draw Signature', value: 'draw' },
            { label: 'Upload Signature', value: 'upload' }
        ];
    }

    // Check if canvas has actual drawing content
    updateSignatureStatus() {
        // Ensure canvas and context are available
        if (!canvasElement || !ctx) {
            this.hasSignature = false;
            return;
        }

        if (this.signatureMode === 'draw') {
            try {
                // Check if canvas has any non-transparent pixels
                const imageData = ctx.getImageData(0, 0, canvasElement.width, canvasElement.height);
                const pixels = imageData.data;
                
                // Check if any pixel has alpha > 0 (non-transparent)
                for (let i = 3; i < pixels.length; i += 4) {
                    if (pixels[i] > 0) {
                        this.hasSignature = true;
                        return;
                    }
                }
                this.hasSignature = false;
            } catch (error) {
                console.log('Error checking canvas content:', error);
                // Don't change hasSignature if we can't check - preserve current state
            }
        } else if (this.signatureMode === 'upload') {
            // For upload mode, check if we have uploaded image data
            this._hasSignature = !!this.uploadedImageData;
        }
    }

    get isButtonDisabled() {
        return !this._hasSignature;
    }
    
    // Method to update button state without causing reactivity
    updateButtonState() {
        const button = this.template.querySelector('lightning-button[label="Capture Signature"]');
        if (button) {
            button.disabled = !this._hasSignature;
        }
    }

    searchCoordinatesForEvent(requestedEvent, event){
        event.preventDefault();
        
        // Disable drawing when in upload mode
        if (this.signatureMode === 'upload') {
            return;
        }
        
        if (requestedEvent === 'down') {
            this.setupCoordinate(event);
            startX = currX;
            startY = currY;
            isDownFlag = true;
            isDotFlag = true;
            hasActualDrawing = false;
            // Don't draw dot immediately - wait for movement
        }
        if (requestedEvent === 'up' || requestedEvent === "out") {
            // Only set signature flag if there was actual drawing movement
            if (hasActualDrawing) {
                this._hasSignature = true;
                // Force button update without causing re-render
                this.updateButtonState();
            }
            isDownFlag = false;
            hasActualDrawing = false;
        }
        if (requestedEvent === 'move') {
            if (isDownFlag) {
                this.setupCoordinate(event);
                
                // Check if there's significant movement from start position
                const distanceFromStart = Math.sqrt(
                    Math.pow(currX - startX, 2) + Math.pow(currY - startY, 2)
                );
                
                if (distanceFromStart > 3) {
                    hasActualDrawing = true;
                    // Draw initial dot if this is first significant movement
                    if (isDotFlag) {
                        this.drawDot();
                        isDotFlag = false;
                    }
                    this.redraw();
                }
            }
        }
    }

    setupCoordinate(eventParam){
        const clientRect = canvasElement.getBoundingClientRect();
        prevX = currX;
        prevY = currY;
        currX = eventParam.clientX -  clientRect.left;
        currY = eventParam.clientY - clientRect.top;
    }

    redraw() {
        ctx.beginPath();
        ctx.moveTo(prevX, prevY);
        ctx.lineTo(currX, currY);
        ctx.strokeStyle = x; //sets the color, gradient and pattern of stroke
        ctx.lineWidth = y;
        ctx.closePath(); //create a path from current point to starting point
        ctx.stroke(); //draws the path
        // Don't update signature status here - only on mouse up after actual drawing
    }
    //this draws the dot - only if there was actual mouse movement
    drawDot(){
        ctx.beginPath();
        ctx.fillStyle = x; //blue color
        ctx.fillRect(currX, currY, y, y); //fill rectrangle with coordinates
        ctx.closePath();
    }
}