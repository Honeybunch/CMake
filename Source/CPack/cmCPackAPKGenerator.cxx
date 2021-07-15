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
  return false;
}

int cmCPackAPKGenerator::PackageFiles()
{
  cmCPackLogger(cmCPackLog::LOG_DEBUG,
                "Toplevel: " << this->toplevel << std::endl);

  /* Reset package file name list it will be populated after the
   * `CPackAPK.cmake` run */
  this->packageFileNames.clear();

  auto retval = this->ReadListFile("Internal/CPack/CPackAPK.cmake");
  if (retval) {
    this->AddGeneratedPackageNames();
  } else {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Error while execution CPackAPK.cmake" << std::endl);
  }

  return retval;
}

void cmCPackAPKGenerator::AddGeneratedPackageNames()
{
  const char* const files_list = this->GetOption("GEN_CPACK_OUTPUT_FILES");
  if (!files_list) {
    cmCPackLogger(
      cmCPackLog::LOG_ERROR,
      "Error while execution CPackAPK.cmake: No APK package has generated"
        << std::endl);
    return;
  }
  // add the generated packages to package file names list
  std::string fileNames{ files_list };
  const char sep = ';';
  std::string::size_type pos1 = 0;
  std::string::size_type pos2 = fileNames.find(sep, pos1 + 1);
  while (pos2 != std::string::npos) {
    this->packageFileNames.push_back(fileNames.substr(pos1, pos2 - pos1));
    pos1 = pos2 + 1;
    pos2 = fileNames.find(sep, pos1 + 1);
  }
  this->packageFileNames.push_back(fileNames.substr(pos1, pos2 - pos1));
}
