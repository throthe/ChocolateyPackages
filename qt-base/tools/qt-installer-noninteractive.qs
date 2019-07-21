Mode = {}
Mode.INSTALLER = 1
Mode.UPDATER = 2
Mode.UNINSTALLER = 3

settings = {}
settings.mode = Mode.INSTALLER;
settings.componentsToAdd = [];
settings.componentsToRemove = [];
settings.installPath = null;
settings.includePreview = false;
settings.listComponents = false;
settings.allPackageSources = ['Archive', 'LTS', 'Latest releases', 'Preview'];
settings.allPackageSources = ['Latest releases'];

LOG = {}
LOG.DEBUG = 'debug';
LOG.INFO = 'info';
LOG.WARN = 'warn';
LOG.ERROR = 'error';
LOG.COMPONENT = 'component'
LOG.log = function (msg, level) {
    level = level || LOG.DEBUG;

    prefix = 'choco:' + level;

    if (level == LOG.ERROR) {
        console.log(prefix);
        console.log(prefix + ' --------------------------------------------------------------------------------------------');
        console.log(prefix + ' - ERROR: ' + msg);
    } else {
        console.log(prefix + ' - ' + msg);
    }
}

function Controller() {

    LOG.log('Loaded non-interactive install script.', LOG.INFO);

    LOG.log('isInstaller: ' + installer.isInstaller());
    LOG.log('isUpdater: ' + installer.isUpdater());
    LOG.log('isUninstaller: ' + installer.isUninstaller());

    toInstall = installer.value('install');
    toRemove = installer.value('remove');
    LOG.log('install="' + toInstall + '"', LOG.DEBUG);
    LOG.log('remove="' + toRemove + '"', LOG.DEBUG);

    if (toInstall.length == 0 && toRemove.length == 0) {
        LOG.log('No components were supplied. This will ONLY install Qt Creator.', LOG.WARN);
    }

    if (toInstall && toInstall.length > 0) {
        settings.componentsToAdd = toInstall.split(' ');
    }

    // Use full uninstaller mode if we're removing everything
    if (toRemove == 'all') {
        LOG.log('Performing complete uninstallation.', LOG.WARN);

        settings.mode = Mode.UNINSTALLER;
        toRemove = '';
    }

    if (toRemove && toRemove.length > 0) {
        settings.componentsToRemove = toRemove.split(' ')
    }

    installPath = installer.value('installDir');
    if (installPath && installPath.length > 0) {
        LOG.log('installDir="' + installPath + '"', LOG.DEBUG);
        settings.installPath = installPath;
    }

    listComponents = installer.value('listComponents');
    if (listComponents && listComponents.length > 0) {
        LOG.log('listComponents=' + listComponents, LOG.DEBUG);
        settings.listComponents = true;
    }

    // Allow selecting components from the preview repository
    includePreview = installer.value('includePreview');
    if (includePreview && includePreview.length > 0) {
        LOG.log('Allowing Qt component selection from source Preview.', LOG.INFO);
        settings.includePreview = true;
    }

    // Handle any message boxes
    installer.autoRejectMessageBoxes()
    installer.setMessageBoxAutomaticAnswer('cancelInstallation', QMessageBox.Yes);
    installer.setMessageBoxAutomaticAnswer('installationError', QMessageBox.Ok);
    installer.setMessageBoxAutomaticAnswer('installationErrorWithRetry', QMessageBox.Cancel);
    installer.setMessageBoxAutomaticAnswer('OverwriteTargetDirectory', QMessageBox.Yes);
    installer.setMessageBoxAutomaticAnswer('AuthorizationError', QMessageBox.Abort);
    // installer.setMessageBoxAutomaticAnswer('DownloadError', QMessageBox.Cancel);
    // installer.setMessageBoxAutomaticAnswer('archiveDownloadError', QMessageBox.Cancel);
    // installer.setMessageBoxAutomaticAnswer('stopProcessesForUpdates', QMessageBox.Cancel);

    installer.componentAdded.connect(function(comp) {
        LOG.log('Success callback. Added: ' + comp.name + ' (' + comp.displayName + ')');
    });
    installer.finishUpdaterComponentsReset.connect(function (x) {
        LOG.log('finishUpdaterComponentsReset: ' + x);
    });
    installer.updaterComponentsAdded.connect(function (x) {
        LOG.log('updaterComponentsAdded: ' + x);
    });

    installer.installationInterrupted.connect(function() {
        LOG.log('Installation interrupted.', LOG.INFO);
    });
    installer.installationFinished.connect(function() {
        LOG.log('Installation finished.', LOG.INFO);
        gui.clickButton(buttons.NextButton);
    });
    installer.updateFinished.connect(function() {
        LOG.log('Update finished.', LOG.INFO);
        gui.clickButton(buttons.NextButton);
    });
    installer.uninstallationFinished.connect(function() {
        LOG.log('Uninstallation finished.', LOG.INFO);
        gui.clickButton(buttons.NextButton);
    });

    installer.metaJobInfoMessage.connect(function (msg) {
        LOG.log(msg, LOG.INFO);
    });
    installer.metaJobProgress.connect(function(val) {
        if (val > 0 && val % 10 == 0) {
            LOG.log('Downloading meta information: ' + val + '%', LOG.INFO);
        }
    });
}

Controller.prototype.WelcomePageCallback = function() {
    LOG.log('Reached welcome page.', LOG.DEBUG);

    // Delay here because the next button is initially disabled for ~1 second
    gui.clickButton(buttons.NextButton, 3000);

    LOG.log('Leaving welcome page.', LOG.DEBUG);
};

Controller.prototype.CredentialsPageCallback = function() {
    LOG.log('Reached credentials page.', LOG.DEBUG);

    var credentialError = function(errrorName) {
        LOG.log('Qt account login failed with "' + errrorName + '" error.', LOG.ERROR);
        gui.reject();
    }

    login = installer.environmentVariable('QT_LOGIN');
    password = installer.environmentVariable('QT_PASSWORD');

    if (login.length > 0 && password.length > 0) {
        LOG.log('Using credentials for ' + login + '.', LOG.INFO);
    } else {
        // Require both to even try
        login = '';
        password = '';
        LOG.log('Resetting credential information.', LOG.INFO);
    }

    page = gui.currentPageWidget();

    gui.findChild(page, 'EmailLineEdit').setText(login);
    gui.findChild(page, 'PasswordLineEdit').setText(password);

    // Next button will be disabled if credential format was invalid
    if (!gui.isButtonEnabled(buttons.NextButton)) {
        credentialError('Invalid login or password format');
        return;
    }

    // Handle credential errors
    page.loginErrorQtAccountChangeDetected.connect(function() {
        credentialError('loginErrorQtAccountChangeDetected');
        return;
    });
    page.licenseDownloadError.connect(function() {
        credentialError('licenseDownloadError');
        return;
    });
    page.allLicensesExpired.connect(function() {
        credentialError('allLicensesExpired');
        return;
    });
    page.noValidLicenseForThisHost.connect(function() {
        credentialError('noValidLicenseForThisHost');
        return;
    });
    page.emailNotVerified.connect(function() {
        credentialError('emailNotVerified');
        return;
    });
    page.credentialsPageCompleted.connect(function() {
        credentialError('credentialsPageCompleted');
        return;
    });
    page.licensemanagerError.connect(function() {
        credentialError('licensemanagerError');
        return;
    });

    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving credentials page.', LOG.DEBUG);
};

Controller.prototype.IntroductionPageCallback = function() {
    LOG.log('Reached introduction page.', LOG.DEBUG);

    page = gui.currentPageWidget()

    // Only do uninstall if we're uninstalling everything
    // Don't select a radio button if this is the first time install
    if (settings.mode == Mode.UNINSTALLER) {
        gui.findChild(page, 'UninstallerRadioButton').click();
    } else if (settings.mode == Mode.UPDATER) {
        gui.findChild(page, 'PackageManagerRadioButton').click();
    }

    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving introduction page.', LOG.DEBUG);
};

Controller.prototype.TargetDirectoryPageCallback = function() {
    LOG.log('Reached target directory page.', LOG.DEBUG);

    // Default path if we didn't receive one
    if (!settings.installPath) {
        installPath = installer.environmentVariable('SYSTEMDRIVE') + '/Qt';
    }

    LOG.log('Install directory set to: ' + installPath, LOG.INFO);

    gui.currentPageWidget().TargetDirectoryLineEdit.setText(installPath);
    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving target directory page.', LOG.DEBUG);
};

Controller.prototype.ComponentSelectionPageCallback = function() {
    LOG.log('Reached component selection page.', LOG.DEBUG);

    var page = gui.currentPageWidget();

    // Print page properties
    // Helpful for finding button names
    // for (var prop in page) {
    //     LOG.log(prop, LOG.DEBUG);
    // }

    // If CategoryGroupBox is visible, check all comboboxes and fetch
    // This ensures that the most inclusive list of packages is available
    var categoryBox = gui.findChild(page, 'CategoryGroupBox');
    if (categoryBox) {

        // Print all categoryBox properties
        // for (var prop in categoryBox) {
        //     LOG.log(prop, LOG.DEBUG);
        // }

        var needsRefresh = false;
        for (var i = 0; i < settings.allPackageSources.length; i++) {
            source = settings.allPackageSources[i]
            checkBox = categoryBox[source]

            // Skip preview features
            if (checkBox.text === 'Preview' && !settings.includePreview) {
                LOG.log('Disabling component source: Preview', LOG.INFO);
                LOG.log('Pass include_preview=true to change this behavior.', LOG.INFO);

                if (checkBox.checked) {
                    checkBox.click();
                    needsRefresh = true;
                }

                continue;
            }

            LOG.log('Enabling component source: ' + source, LOG.INFO);

            if (checkBox.checked == false) {
                checkBox.click();
                needsRefresh = true;
            }
        }

        // Refreshing requires fetching new metadata
        // Don't refresh unless we have to
        if (needsRefresh) {
            var fetchButton = categoryBox.FetchCategoryButton
            if (fetchButton) {
                LOG.log('Refreshing component sources...', LOG.INFO);
                fetchButton.click();
            } else {
                LOG.log('Could not find fetch button. All component sources may not be enabled.', LOG.WARN);
            }
        }
    } else {
        LOG.log('Could not find group box. All component sources may not be enabled.', LOG.WARN);
    }

    // Create a dictionary of all the component names
    allComponentsList = installer.components();
    allComponents = {}
    for (var i = 0; i < allComponentsList.length; i++) {
        comp = allComponentsList[i];
        allComponents[comp.name] = comp;

        if (settings.listComponents) {
            LOG.log(comp.displayName + ' = ' + comp.name, LOG.COMPONENT);
        }
    }

    // Exit after printing the component list
    if (settings.listComponents) {
        gui.reject();
        return;
    }

    page.deselectAll();

    for (var i = 0; i < settings.componentsToAdd.length; i++) {
        compName = settings.componentsToAdd[i].trim();

        if (compName in allComponents) {
            comp = allComponents[compName]

            LOG.log(comp.installed)
            LOG.log(comp.isInstalled())
            LOG.log(comp.installationRequested())

            page.selectComponent(compName);
            LOG.log('Selected: ' + compName, LOG.INFO);
        } else {
            LOG.log('Could not find ' + compName + ' in the Qt component list.', LOG.ERROR);

            gui.reject();
            return;
        }
    }

    for (var i = 0; i < settings.componentsToRemove.length; i++) {
        compName = settings.componentsToRemove[i].trim();

        if (compName in allComponents) {
            comp = allComponents[compName]

            LOG.log(comp.installed)
            LOG.log(comp.isInstalled())
            LOG.log(comp.installationRequested())

            page.deselectComponent(compName);
            LOG.log('Deselected: ' + compName, LOG.INFO);
        } else {
            LOG.log('Could not find ' + compName + ' in the Qt component list.', LOG.ERROR);

            gui.reject();
            return;
        }
    }

    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving component selection page.', LOG.DEBUG);
};

Controller.prototype.LicenseAgreementPageCallback = function() {
    LOG.log('Reached license agreement page.', LOG.DEBUG);

    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    LOG.log('Accepted all licenses.', LOG.INFO);

    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving license agreement page.', LOG.DEBUG);
};

Controller.prototype.StartMenuDirectoryPageCallback = function() {
    LOG.log('Reached start menu directory page.', LOG.DEBUG);

    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving start menu directory page.', LOG.DEBUG);
};

Controller.prototype.ReadyForInstallationPageCallback = function() {
    LOG.log('Reached ready for installation page.', LOG.DEBUG);

    bytes = installer.requiredDiskSpace();
    gigaBytes = bytes / 1024.0 / 1024.0 / 1024.0;
    gigaBytes = Math.round(gigaBytes * 100) / 100.0
    LOG.log('Changes will require ' + gigaBytes + ' GB of disk space.', LOG.WARN);

    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving ready for installation page.', LOG.DEBUG);
};

Controller.prototype.PerformInstallationPageCallback = function() {
    LOG.log('Reached perform installation page.', LOG.DEBUG);

    if (settings.mode == Mode.UNINSTALLER) {
        LOG.log('Starting uninstall...', LOG.INFO);
    } else {
        LOG.log('Starting download and installation. This may take awhile...', LOG.WARN);
    }

    var page = gui.currentPageWidget();

    var progressBar = page.ProgressBar
    progressBar.valueChanged.connect(function(value) {
        if (value % 5 == 0) {
            LOG.log('Progress: ' + value + '%', LOG.INFO);
        }
    });

    LOG.log('Leaving perform installation page.', LOG.DEBUG);
}

Controller.prototype.FinishedPageCallback = function() {
    LOG.log('Reached finished page.', LOG.DEBUG);

    var checkBoxForm = gui.currentPageWidget().LaunchQtCreatorCheckBoxForm;
    if (checkBoxForm && checkBoxForm.launchQtCreatorCheckBox) {
        checkBoxForm.launchQtCreatorCheckBox.checked = false;
        LOG.log('Unchecked launch Qt creator button.', LOG.DEBUG);
    }

    gui.clickButton(buttons.FinishButton);

    LOG.log('Leaving finished page.', LOG.DEBUG);
};
