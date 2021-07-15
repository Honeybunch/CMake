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

protected:
  bool SupportsComponentInstallation() const override;

  /**
   * The main package file method.
   * If component install was required this
   * method will call either PackageComponents or
   * PackageComponentsAllInOne.
   */
  int PackageFiles() override;

  const char* GetOutputExtension() override { return ".apk"; }

private:
  /**
   * Populate \c packageFileNames vector of built packages.
   */
  void AddGeneratedPackageNames();
};
