allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Use a single shared build directory (Flutter compatible)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    project.layout.buildDirectory.value(newBuildDir.dir(project.name))
}

// CLEAN TASK
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
