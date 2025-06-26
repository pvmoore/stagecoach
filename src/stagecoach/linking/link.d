module stagecoach.linking.link;

import stagecoach.all;

/**
 * Call the external linker to create the executable
 */
bool linkProject(Project project) {
    return msLink(project);
}
