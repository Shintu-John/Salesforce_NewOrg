/**
 * @description Automatically backfill Producer sharing when new portal users are created
 * @purpose Ensures new portal users immediately have access to existing Producer records
 * @created 2025-10-21
 */
trigger UserSharingBackfill on User (after insert, after update) {

    // Collect portal users that need sharing backfill
    List<Id> usersNeedingBackfill = new List<Id>();

    for (User u : Trigger.new) {
        Boolean needsBackfill = false;

        // Check if this is a new portal user with a Contact
        if (Trigger.isInsert && u.ContactId != null) {
            needsBackfill = true;
        }

        // Check if Contact changed (user moved to different Account)
        if (Trigger.isUpdate && u.ContactId != null) {
            User oldUser = Trigger.oldMap.get(u.Id);
            if (u.ContactId != oldUser.ContactId) {
                needsBackfill = true;
            }
        }

        // Only process if user needs backfill
        if (needsBackfill) {
            usersNeedingBackfill.add(u.Id);
        }
    }

    // Trigger backfill for qualifying users
    if (!usersNeedingBackfill.isEmpty()) {
        System.debug('UserSharingBackfill trigger: ' + usersNeedingBackfill.size() + ' users need sharing backfill');
        UserSharingBackfillHelper.backfillSharingForNewUsers(usersNeedingBackfill);
    }
}