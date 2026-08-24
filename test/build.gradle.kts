repositories {
    mavenCentral()
}

plugins {
    kotlin("jvm") version "2.3.10"
    kotlin("plugin.serialization") version "2.3.10"
}

group = "com.yandex"
version = "1.0-SNAPSHOT"

dependencies {
    testImplementation(project(":plugin-tests-support"))
    testImplementation("com.yandex.mobile.testcop:testcop-testng:0.0.1")
    testImplementation("io.appium:java-client:10.0.0")
}

tasks.test {
    useTestNG {
        suiteXmlFiles = listOf(File("src/test/resources/testng.xml"))
    }
    System.getProperty("testcop.skips.path")?.let { systemProperty("testcop.skips.path", it) }
    System.getProperty("testcop.mutes.path")?.let { systemProperty("testcop.mutes.path", it) }
}

val javaToolchainVersion = providers.gradleProperty("javaToolchainVersion")
    .map(String::toInt)
    .orElse(JavaVersion.current().majorVersion.toInt())

kotlin {
    jvmToolchain(javaToolchainVersion.get())
}
