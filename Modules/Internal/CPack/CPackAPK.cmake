# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

# Author: Arsen Tufankjian

if(CMAKE_BINARY_DIR)
  message(FATAL_ERROR "CPackAPK.cmake may only be used by CPack internally.")
endif()

find_package(Java 1.8)
find_package(Java COMPONENTS Development)
include(UseJava)

get_filename_component(JAVA_HOME ${Java_JAVA_EXECUTABLE} DIRECTORY)
file(REAL_PATH "${JAVA_HOME}/../" JAVA_HOME)

# Variables
# TODO: Auto-detect better defaults
if(NOT CPACK_APK_ANDROID_VERSION)
  set(CPACK_APK_ANDROID_VERSION 29)
endif()
if(NOT CPACK_APK_TOOL_VERSION_MAJOR)
  set(CPACK_APK_TOOL_VERSION_MAJOR 29)
endif()
if(NOT CPACK_APK_TOOL_VERSION_MINOR)
  set(CPACK_APK_TOOL_VERSION_MINOR 0)
endif()
if(NOT CPACK_APK_TOOL_VERSION_PATCH)
  set(CPACK_APK_TOOL_VERSION_PATCH 3)
endif()
if(NOT CPACK_APK_TOOL_VERSION)
  set(CPACK_APK_TOOL_VERSION ${CPACK_APK_TOOL_VERSION_MAJOR}.${CPACK_APK_TOOL_VERSION_MINOR}.${CPACK_APK_TOOL_VERSION_PATCH})
endif()
if(NOT CPACK_APK_GEN_DEBUG_KEYSTORE)
  set(CPACK_APK_GEN_DEBUG_KEYSTORE TRUE)
endif()

# MUST BE USER SUPPLIED
if(NOT CPACK_APK_NDK_PATH)
  message(FATAL_ERROR "Must provide path to Android NDK in CPACK_APK_NDK_PATH")
endif()
if(NOT CPACK_APK_KEYSTORE_PATH)
  message(FATAL_ERROR "Must provide path to existing .keystore file or the location for a default .keystore to be generated in CPACK_APK_KEYSTORE_PATH")
endif()

# TODO: A more robust way of finding the Android *SDK*???
set(BUILD_TOOLS_DIR ${CPACK_APK_NDK_PATH}/../../build-tools/${CPACK_APK_TOOL_VERSION}/)
get_filename_component(BUILD_TOOLS_DIR ${BUILD_TOOLS_DIR} ABSOLUTE)

set(PLATFORMS_DIR ${CPACK_APK_NDK_PATH}/../../platforms)
set(ANDROID_DIR ${PLATFORMS_DIR}/android-${CPACK_APK_ANDROID_VERSION}/)
get_filename_component(ANDROID_DIR ${ANDROID_DIR} ABSOLUTE)

find_program(AAPT aapt
             PATHS ${BUILD_TOOLS_DIR}
             REQUIRED)
find_file(APKSIGNER NAMES apksigner.bat apksigner.sh
          PATHS ${BUILD_TOOLS_DIR}
          REQUIRED)
find_file(DX NAMES dx.bat dx.sh
          PATHS ${BUILD_TOOLS_DIR}
          REQUIRED)
find_program(ZIPALIGN zipalign
             PATHS ${BUILD_TOOLS_DIR}
             REQUIRED)
find_program(KEYTOOL keytool
             PATHS ${JAVA_HOME}/bin
             REQUIRED)
find_file(ANDROID_JAR android.jar
          PATHS ${ANDROID_DIR}
          REQUIRED)

set(unaligned_apk_path ${CPACK_TEMPORARY_DIRECTORY}/${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-unaligned.apk)
set(apk_path ${CPACK_TEMPORARY_DIRECTORY}/${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}.apk)

# Create signing keys
if(NOT EXISTS ${CPACK_TEMPORARY_DIRECTORY}/${CPACK_APK_KEYSTORE_PATH})
  if(CPACK_APK_GEN_DEBUG_KEYSTORE)
    execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}
                    COMMAND ${CMAKE_COMMAND} -E env "JAVA_HOME=${JAVA_HOME}" ${KEYTOOL} -genkeypair -keystore ${CPACK_APK_KEYSTORE_PATH} -storepass android -alias androiddebugkey -keypass android -keyalg RSA -validity 10000 -dname CN=,OU=,O=,L=,S=,C=)
  endif()
endif()

# Glob jars and then turn that list into something CLI friendly
file(GLOB_RECURSE CPACK_APK_JAR_LIST ${CPACK_TEMPORARY_DIRECTORY}/*.jar)

# Create Compile Java to DEX
execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}
                COMMAND ${CMAKE_COMMAND} -E make_directory bin
                COMMAND ${CMAKE_COMMAND} -E env "JAVA_HOME=${JAVA_HOME}" ${DX} --dex --output=bin/classes.dex ${CPACK_APK_JAR_LIST}
)

# Create APK
execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}
                COMMAND ${AAPT} package -v -f -S ./res -A ./assets -M ${CPACK_APK_MANIFEST_PATH} -I ${ANDROID_JAR} -F ${unaligned_apk_path} ./bin
)

# Have to allow the user to supply a list of extra goodies to package in
foreach(item ${CPACK_APK_PACKAGE_LIST})
  execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}
                  COMMAND ${AAPT} add -v ${unaligned_apk_path} ${item})
endforeach()

foreach(arch ${CPACK_APK_PACKAGE_ARCH_LIST})
  file(GLOB_RECURSE ARCH_SHARED_OBJECTS ${CPACK_TEMPORARY_DIRECTORY}/lib/${arch}/*.so)

    foreach(so ${ARCH_SHARED_OBJECTS})
      file(RELATIVE_PATH so ${CPACK_TEMPORARY_DIRECTORY} ${so})
      execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}
                      COMMAND ${AAPT} add -v ${unaligned_apk_path} ${so})
    endforeach()
endforeach()

# Zip, Align & Verify
# TODO: Allow signing with release credentials
execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}
                COMMAND ${CMAKE_COMMAND} -E env "JAVA_HOME=${JAVA_HOME}" ${ZIPALIGN} -f 4 ${unaligned_apk_path} ${apk_path})
execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}
                COMMAND ${CMAKE_COMMAND} -E env "JAVA_HOME=${JAVA_HOME}" ${APKSIGNER} sign -v --ks ${CPACK_APK_KEYSTORE_PATH} --ks-pass pass:android --key-pass pass:android --ks-key-alias androiddebugkey ${apk_path})
execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY}
                COMMAND ${CMAKE_COMMAND} -E env "JAVA_HOME=${JAVA_HOME}" ${APKSIGNER} verify -v ${apk_path})

execute_process(WORKING_DIRECTORY ${CPACK_TEMPORARY_DIRECTORY} COMMAND ${CMAKE_COMMAND} -E remove -f ${unaligned_apk_path})

# Report to CPack that we packaged an apk
file(GLOB_RECURSE GEN_CPACK_OUTPUT_FILES "${CPACK_TEMPORARY_DIRECTORY}/*.apk")
if(NOT GEN_CPACK_OUTPUT_FILES)
    message(FATAL_ERROR "APK package was not generated at `${CPACK_TEMPORARY_DIRECTORY}`!")
endif()
