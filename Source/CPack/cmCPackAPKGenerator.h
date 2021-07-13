/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file Copyright.txt or https://cmake.org/licensing for details.  */
#pragma once

#include "cmCPackGenerator.h"

/** \class cmCPackAPKGenerator
 * \brief A generator for Android APK packages
 */
class cmCPackAPKGenerator : public cmCPackGenerator
{
public:
  cmCPackTypeMacro(cmCPackAPKGenerator, cmCPackGenerator);

  // Do we want to check to see if we can find the Android SDK here?
  // static bool CanGenerate() { return true; }

  bool SupportsComponentInstallation() const override;
  int PackageFiles() override;

  const char* GetOutputExtension() override { return ".apk"; }

  /**
   * The method used to prepare variables when component
   * install is used.
   */
  void SetupGroupComponentVariables(bool ignoreGroup);
  /**
   * Populate \c packageFileNames vector of built packages.
   */
  void AddGeneratedPackageNames();
};
