import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Use a build directory without spaces to avoid Windows path escaping issues.
val rootBuildDir = file("C:/AgroSmartBuild/agri_mobile")
rootProject.buildDir = rootBuildDir

subprojects {
    buildDir = File(rootBuildDir, name)
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
