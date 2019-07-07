settings = {}
settings.showComponents = false;
settings.includePreview = false;
settings.packageSources = ['Archive', 'LTS', 'Latest releases', 'Preview'];
settings.packageSources = ['Latest releases'];

function Controller() {

    LOG.log('Loaded non-interactive install script.', LOG.INFO);

    // Default NO to all messages boxes with retry options
    // We want to give up and fall back to Chocolatey
    installer.setMessageBoxAutomaticAnswer('cancelInstallation', QMessageBox.Yes);
    installer.setMessageBoxAutomaticAnswer('installationError', QMessageBox.Ok);
    installer.setMessageBoxAutomaticAnswer('installationErrorWithRetry', QMessageBox.Cancel);
    installer.setMessageBoxAutomaticAnswer('OverwriteTargetDirectory', QMessageBox.Yes);
    // installer.setMessageBoxAutomaticAnswer('AuthorizationError', QMessageBox.Abort);
    // installer.setMessageBoxAutomaticAnswer('DownloadError', QMessageBox.Cancel);
    // installer.setMessageBoxAutomaticAnswer('archiveDownloadError', QMessageBox.Cancel);
    // installer.setMessageBoxAutomaticAnswer('stopProcessesForUpdates', QMessageBox.Cancel);

    // Attach to lots of callbacks for debugging
    installer.componentAdded.connect(function(comp) {
        LOG.log('Success callback. Added: ' + comp.name + ' (' + comp.displayName + ')');
    });
    installer.finishUpdaterComponentsReset.connect(function (x) {
        LOG.log('finishUpdaterComponentsReset: ' + x);
    });
    installer.updaterComponentsAdded.connect(function (x) {
        LOG.log('updaterComponentsAdded: ' + x);
    });
    installer.statusChanged.connect(function (x) {
        LOG.log('statusChanged: ' + x);
    });
    installer.installationFinished.connect(function (x) {
        LOG.log('installationFinished: ' + x);
    });
    installer.updateFinished.connect(function (x) {
        LOG.log('updateFinished: ' + x);
    });
    installer.titleMessageChanged.connect(function (x) {
        LOG.log('titleMessageChanged: ' + x);
    });

    installer.metaJobInfoMessage.connect(function (msg) {
        LOG.log(msg, LOG.INFO);
    });
    installer.metaJobProgress.connect(function(val) {
        if (val > 0 && val % 10 == 0) {
            LOG.log('Downloading meta information: ' + val + '%');
        }
    });
}

LOG = {}
LOG.DEBUG = 'debug';
LOG.INFO = 'info';
LOG.WARN = 'warn';
LOG.ERROR = 'error';
LOG.COMPONENT = 'component'
LOG.log = function (msg, level) {
    level = level || LOG.DEBUG;
    console.log('choco:' + level + ' - ' + msg);
}

Controller.prototype.WelcomePageCallback = function() {
    LOG.log('Reached welcome page.', LOG.DEBUG);

    // Delay here because the next button is initially disabled for ~1 second
    gui.clickButton(buttons.NextButton, 3000);

    LOG.log('Leaving welcome page.', LOG.DEBUG);
};

Controller.prototype.CredentialsPageCallback = function() {
    LOG.log('Reached credentials page.', LOG.DEBUG);

    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving credentials page.', LOG.DEBUG);
};

Controller.prototype.IntroductionPageCallback = function() {
    LOG.log('Reached introduction page.', LOG.DEBUG);

    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving introduction page.', LOG.DEBUG);
};

Controller.prototype.TargetDirectoryPageCallback = function() {
    LOG.log('Reached target directory page.', LOG.DEBUG);

    installPath = installer.environmentVariable('SYSTEMDRIVE') + '/Qt';
    LOG.log('Setting install directory to: ' + installPath, LOG.INFO);

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
        LOG.log(categoryBox)

        // Print all categoryBox properties
        // for (var prop in categoryBox) {
        //     LOG.log(prop, LOG.DEBUG);
        // }

        var needsRefresh = false;
        for (var i = 0; i < settings.packageSources.length; i++) {
            source = settings.packageSources[i]
            checkBox = categoryBox[source]

            // Skip preview features
            if (checkBox.text === 'Preview' && !settings.includePreview) {
                LOG.log('Skipping component source (disabled): Preview', LOG.INFO);
                continue;
            }

            LOG.log('Enabling component source: ' + source, LOG.INFO);

            if (checkBox.checked == false) {
                checkBox.click();
                needsRefresh = true;
            }
        }

        // Don't refresh unless we have to
        // Requires fetching new metadata
        if (needsRefresh) {
            var fetchButton = categoryBox.FetchCategoryButton
            if (fetchButton) {
                LOG.log('Found fetch button.', LOG.DEBUG);
                fetchButton.click();
            } else {
                LOG.log('Could not find fetch button. All component sources may not be enabled.', LOG.ERROR);
            }
        }
    } else {
        LOG.log('Could not find group box. All component sources may not be enabled.', LOG.ERROR);
    }

    // Create a dictionary of all the component names
    allComponentsList = installer.components();
    allComponents = {}
    for (var i = 0; i < allComponentsList.length; i++) {
        comp = allComponentsList[i];
        allComponents[comp.name] = comp.displayName;

        if (settings.showComponents) {
            LOG.log(comp.displayName + ' = ' + comp.name, LOG.COMPONENT);
        }
    }

    page.deselectAll();

    userComponents = installer.value('components');
    LOG.log('Full component list: ' + userComponents, LOG.INFO);
    userComponents = userComponents.split(' ');

    for (var i = 0; i < userComponents.length; i++) {
        comp = userComponents[i].trim();

        if (comp in allComponents) {
            LOG.log('Selecting: ' + comp, LOG.INFO);
            page.selectComponent(comp);
        } else {
            LOG.log('', LOG.ERROR);
            LOG.log('--------------------------------------------------------------------------------------------', LOG.ERROR);
            LOG.log('| ERROR: Could not find ' + comp + ' in the Qt component list.', LOG.ERROR);

            gui.reject();
            return;
        }
    }

    // gui.clickButton(buttons.NextButton);

    LOG.log('Leaving component selection page.', LOG.DEBUG);
};

Controller.prototype.LicenseAgreementPageCallback = function() {
    LOG.log('Reached license agreement page.', LOG.DEBUG);

    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);

    LOG.log('Leaving license agreement page.', LOG.DEBUG);
};

Controller.prototype.StartMenuDirectoryPageCallback = function() {
    LOG.log('Reached start menu directory page.', LOG.DEBUG);

    // gui.clickButton(buttons.NextButton);

    // LOG.log('Leaving start menu directory page.', LOG.DEBUG);
};

Controller.prototype.ReadyForInstallationPageCallback = function() {
    LOG.log('Reached ready for installation page.', LOG.DEBUG);

    // gui.clickButton(buttons.NextButton);

    // LOG.log('Leaving ready for installation page.', LOG.DEBUG);
};

Controller.prototype.FinishedPageCallback = function() {
    LOG.log('Reached finished page.', LOG.DEBUG);

    var checkBoxForm = gui.currentPageWidget().LaunchQtCreatorCheckBoxForm;
    if (checkBoxForm && checkBoxForm.launchQtCreatorCheckBox) {
        checkBoxForm.launchQtCreatorCheckBox.checked = false;
        LOG.log('Unchecked launch Qt creator button.', LOG.DEBUG);
    }

    // gui.clickButton(buttons.FinishButton);

    // LOG.log('Leaving finished page.', LOG.DEBUG);
};
