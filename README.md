# VH-3rd-Party-Installer

This script creates a Windows installer that installs a variety of 3rd Party redistributables.

The intent is to have a single source for installing all the required components needed to run our Virtual Human software.


The installer bundles these components into a single installer:

* ActiveMQ
* .NET Framework Redistributable 3.5
* DirectX Redistributable (August 2009)
* Visual Studio 2015 Update 2 Redistributable

The ActiveMQ installer will install ActiveMQ as a Windows Service, and will set it to run automatically when Windows starts.  This is a custom installer, and the installer script for this is also provided in this repository.

The rest of the installers are freely available separately from different sources.  This installer simply aims to make the process go smoothly on initial installs.

The installer script uses NSIS installer to generate the installer.  The version used is assumed to be version 2.46.
