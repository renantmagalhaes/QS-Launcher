pragma Singleton
pragma ComponentBehavior: Bound

import QtQml

QtObject {
    signal closeAllModalsExcept(var excludedModal)

    function openModal(modal) {
        closeAllModalsExcept(modal);
    }

    function closeModal(modal) {
    }
}
