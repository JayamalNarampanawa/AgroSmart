import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.1")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

// Use a build directory without spaces to avoid Windows path escaping issues.
val rootBuildDir = file("../build")
rootProject.buildDir = rootBuildDir

subprojects {
    buildDir = File(rootBuildDir, name)
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
