/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file Copyright.txt or https://cmake.org/licensing for details.  */
#include "cmCPackAPKGenerator.h"

#include <algorithm>
#include <iterator>
#include <map>
#include <ostream>
#include <string>
#include <utility>
#include <vector>

#include "cmCPackComponentGroup.h"
#include "cmCPackLog.h"
#include "cmStringAlgorithms.h"
#include "cmSystemTools.h"

bool cmCPackAPKGenerator::SupportsComponentInstallation() const
{
  return this->IsOn("CPACK_APK_COMPONENT_INSTALL");
}

int cmCPackAPKGenerator::PackageFiles()
{
  cmCPackLogger(cmCPackLog::LOG_DEBUG,
                "Toplevel: " << this->toplevel << std::endl);

  /* Reset package file name list it will be populated after the
   * `CPackAPK.cmake` run */
  this->packageFileNames.clear();

  /* Are we in the component packaging case */
  if (this->WantsComponentInstallation()) {
    if (this->componentPackageMethod == ONE_PACKAGE) {
      // CASE 1 : COMPONENT ALL-IN-ONE package
      // Meaning that all per-component pre-installed files
      // goes into the single package.
      this->SetOption("CPACK_APK_ALL_IN_ONE", "TRUE");
      this->SetupGroupComponentVariables(true);
    } else {
      // CASE 2 : COMPONENT CLASSICAL package(s) (i.e. not all-in-one)
      // There will be 1 package for each component group
      // however one may require to ignore component group and
      // in this case you'll get 1 package for each component.
      this->SetupGroupComponentVariables(this->componentPackageMethod ==
                                         ONE_PACKAGE_PER_COMPONENT);
    }
  } else {
    // CASE 3 : NON COMPONENT package.
    this->SetOption("CPACK_APK_ORDINAL_MONOLITIC", "TRUE");
  }

  auto retval = this->ReadListFile("Internal/CPack/CPackAPK.cmake");
  if (retval) {
    this->AddGeneratedPackageNames();
  } else {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Error while execution CPackAPK.cmake" << std::endl);
  }

  return retval;
}

void cmCPackAPKGenerator::SetupGroupComponentVariables(bool ignoreGroup)
{
}

void cmCPackAPKGenerator::AddGeneratedPackageNames()
{
}
