function Get-ReadmeContent {
  <#
  .SYNOPSIS
    Return the text for a Puppet Resource API Type given a DSC Resouce.
  .DESCRIPTION
    Return the text for a Puppet Resource API Type given a DSC Resouce.
    It will return the text but _not_ directly write out the file.
  .PARAMETER PuppetModuleName
    The name of the puppet module
  .PARAMETER PowerShellModuleName
    The name of the PowerShell module being puppetized
  .PARAMETER PowerShellModuleVersion
    The version of the PowerShell module being puppetized
  .PARAMETER PowerShellModuleGalleryUri
    The full url to the PowerShell module on a nuget gallery
  .PARAMETER PowerShellModuleProjectUri
    The full url to the PowerShell module's project page/repository

  .EXAMPLE
    $Parameters = @{
      PowerShellModuleName       = 'Foo.Bar'
      PowerShellModuleGalleryUri = "https://www.powershellgallery.com/packages/Foo.Bar/1.0.0"
      PowerShellModuleProjectUri = 'https://github.com/foo/Foo.Bar'
      PowerShellModuleVersion    = '1.0.0'
      PuppetModuleName           = 'foo_bar'
    }
    Get-ReadmeContent @Parameters

    This command return a markdown readme for the puppetized foo_bar module.
  #>
  [cmdletbinding()]
  param (
    [OutputType([String])]
    [string]$PowerShellModuleName,
    [string]$PowerShellModuleDescription,
    [string]$PowerShellModuleGalleryUri,
    [string]$PowerShellModuleProjectUri,
    [string]$PowerShellModuleVersion,
    [string]$PuppetModuleName
  )

  Begin {
    $BuilderModuleGalleryUri      = 'https://www.powershellgallery.com/packages/puppet.dsc'
    $BuilderModuleRepository      = 'https://github.com/puppetlabs/Puppet.Dsc'
    $BaseProviderSource           = 'https://github.com/puppetlabs/ruby-pwsh/blob/master/lib/puppet/provider/dsc_base_provider.rb'
    $ResourceApiOverview          = 'https://puppet.com/docs/puppet/latest/create_types_and_providers_resource_api.html'
    $ResourceApiDocumentation     = 'https://puppet.com/docs/puppet/latest/about_the_resource_api.html'
    $dscForgePage                 = 'https://forge.puppet.com/dsc'
    $pwshlibForgePage             = 'https://forge.puppet.com/puppetlabs/pwshlib'
    $pwshlibIssuesPage            = 'https://github.com/puppetlabs/ruby-pwsh/issues/new/choose'
    $PowerShellGetUri             = 'https://github.com/PowerShell/PowerShellGet'
    $NarrativeDocumentation       = 'https://puppetlabs.github.io/iac/news/roadmap/2020/03/30/dsc-announcement.html'
    $TroubleshootingDocumentation = 'https://github.com/puppetlabs/Puppet.Dsc#troubleshooting'
  }

  Process {
    # No additional formatting should be needed
    New-Object -TypeName System.String @"
# $PuppetModuleName

## Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Usage](#usage)
1. [Troubleshooting](#troubleshooting)

## Description

This is an auto-generated module, using the [Puppet DSC Builder]($BuilderModuleGalleryUri) to vendor and expose the [$PowerShellModuleName]($PowerShellModuleGalleryUri) PowerShell module's DSC resources as Puppet resources.
The _functionality_ of this module comes entirely from the vendored PowerShell resources, which are pinned at [**v$PowerShellModuleVersion**]($PowerShellModuleGalleryUri).
The PowerShell module describes itself like this:

> _${PowerShellModuleDescription}_

For information on troubleshooting to determine whether any encountered problems are with the Puppet wrapper or the DSC resource, see the [troubleshooting](#troubleshooting) section below.

## Requirements

This module, like all [auto-generated Puppetized DSC modules]($dscForgePage), relies on two important technologies in the Puppet stack: the [Puppet Resource API]($ResourceApiOverview) and the [`puppetlabs/pwshlib`]($pwshlibForgePage) Puppet module.

The Resource API provides a simplified option for writing types and providers and is responsible for how this module is structured.
The Resource API ships inside of Puppet starting with version 6.
While it is _technically_ possible to add the Resource API functionality to Puppet 5.5.x, the DSC functionality has **not** been tested in this setup.
For more information on the Resource API, review the [documentation]($ResourceApiDocumentation).

The module also depends on the `pwshlib` module.
This Puppet module includes two important things: the ruby-pwsh library for running PowerShell code from ruby and the base provider for DSC resources, which this module leverages.

All of the actual work being done to call the DSC resources vendored with this module is in [this file]($BaseProviderSource) from the `pwshlib` module.
This is important for troubleshooting and bug reporting, but doesn't impact your use of the module except that the end result will be that nothing works, as the dependency is not installed alongside this module!

## Usage

You can specify any of the DSC resources from this module like a normal Puppet resource in your manifests.
The examples below use DSC resources from from the [`PowerShellGet`]($PowerShellGetUri) repository, regardless of what module you're looking at here;
the syntax, not the specifics, is what's important.

For reference documentation about the DSC resources exposed in this module, see the *Reference* Forge tab, or the `REFERENCE.md` file.

``````puppet
# Include a meaningful title for your resource declaration
dsc_psrepository { 'Add team module repo':
    dsc_name               => 'foo',
    dsc_ensure             => present,
    # This location is nonsense, can be any valid folder on your
    # machine or in a share, any location the SourceLocation param
    # for the DSC resource will accept.
    dsc_sourcelocation     => 'C:\Program Files',
    # You must always pass an enum fully lower-cased;
    # Puppet is case sensitive even when PowerShell isn't
    dsc_installationpolicy => untrusted,
}

dsc_psrepository { 'Trust public gallery':
    dsc_name               => 'PSGallery',
    dsc_ensure             => present,
    dsc_installationpolicy => trusted,
}

dsc_psmodule { 'Make Ruby manageable via uru':
  dsc_name   => 'RubyInstaller',
  dsc_ensure => present,
}
``````

### Credentials

Credentials are always specified as a hash of the username and password for the account.
The password **must** use the Puppet [Sensitive type](https://puppet.com/docs/puppet/latest/lang_data_sensitive.html);
this ensures that logs and reports redact the password, displaying it instead as `<Sensitive [value redacted]>`.

``````puppet
dsc_psrepository { 'PowerShell Gallery':
  dsc_name                 => 'psgAllery',
  dsc_installationpolicy   => 'Trusted',
  dsc_psdscrunascredential => {
    user     => 'apple',
    password => Sensitive('foobar'),
  },
}
``````

### CIM Instances

Because the CIM instances for DSC resources are fully mapped, the types actually explain fairly precisely what the shape of each CIM instance has to be - and, moreover, the type definition means that you get checking at catalog compile time.
Puppet parses CIM instances are structured hashes (or arrays of structured hashes) that explicitly declare their keys and the valid types of values for each key.

So, for the ``dsc_accesscontrolentry`` property of the ``dsc_ntfsaccessentry`` type, which has a MOF type of ``NTFSAccessControlList[]``, Puppet defines the CIM instance as:

``````ruby
Array[Struct[{
  accesscontrolentry => Array[Struct[{
    accesscontroltype => Enum['Allow', 'Deny'],
    inheritance => Enum['This folder only', 'This folder subfolders and files', 'This folder and subfolders', 'This folder and files', 'Subfolders and files only', 'Subfolders only', 'Files only'],
    ensure => Enum['Present', 'Absent'],
    cim_instance_type => 'NTFSAccessControlEntry',
    filesystemrights => Array[Enum['AppendData', 'ChangePermissions', 'CreateDirectories', 'CreateFiles', 'Delete', 'DeleteSubdirectoriesAndFiles', 'ExecuteFile', 'FullControl', 'ListDirectory', 'Modify', 'Read', 'ReadAndExecute', 'ReadAttributes', 'ReadData', 'ReadExtendedAttributes', 'ReadPermissions', 'Synchronize', 'TakeOwnership', 'Traverse', 'Write', 'WriteAttributes', 'WriteData', 'WriteExtendedAttributes']]
  }]],
  forceprincipal => Optional[Boolean],
  principal => Optional[String],
}]]
``````

A valid example of that in a puppet manifest looks like this:

``````puppet
dsc_accesscontrollist => [
  {
    accesscontrolentry => [
      {
        accesscontroltype => 'Allow',
        inheritance       => 'This folder only',
        ensure            => 'Present',
        filesystemrights  => 'ChangePermissions',
        cim_instance_type => 'NTFSAccessControlEntry',
      },
    ],
    principal          => 'veryRealUserName',
  },
]
``````

For more information about using a built module, check out our [narrative documentation]($NarrativeDocumentation).

### Properties

Note that the only properties specified in a resource declaration which are passed to `Invoke-Dsc` are all prepended with `dsc_`.
If a property does _not_ start with `dsc_` it is used to control how Puppet interacts with DSC/other Puppet resources - for example,
specifying a unique name for the resource for Puppet to distinguish between declarations or Puppet metaparameters (``notifies`, ``before`, etc).

## Troubleshooting

In general, there are three broad categories of problems:

1. Problems with the way the underlying DSC resource works.
1. Problems with the type definition, where you can't specify a valid set of properties for the DSC resource
1. Problems with calling the underlying DSC resource - the parameters aren't being passed correctly or the resource can't be found

Unfortunately, problems with the way the underlying DSC resource works are something we can't help _directly_ with.
You'll need to [file an issue]($PowerShellModuleProjectUri) with the upstream maintainers for the [PowerShell module]($PowerShellModuleGalleryUri).

Problems with the type definition are when a value that should be valid according to the DSC resource's documentation and code is not accepted by the Puppet wrapper. If and when you run across one of these, please [file an issue]($BuilderModuleRepository/issues/new/choose) with the Puppet DSC Builder; this is where the conversion happens and once we know of a problem we can fix it and regenerate the Puppet modules. To help us identify the issue, please specify the DSC module, version, resource, property and values that are giving you issues. Once a fix is available we will regenerate and release updated versions of this Puppet wrapper.

Problems with calling the underlying DSC resource become apparent by comparing ``<value passed in in puppet>`` with ``<value received by DSC>``.
In this case, please [file an issue]($pwshlibIssuesPage) with the [`puppetlabs/pwshlib`]($pwshlibForgePage) module, which is where the DSC base provider actually lives.
We'll investigate and prioritize a fix and update the `puppetlabs/pwshlib` module.
Updating to the pwshlib version with the fix will immediately take advantage of the improved functionality without waiting for this module to be reconverted and published.

For specific information on troubleshooting a generated module, check the [troubleshooting guide]($TroubleshootingDocumentation) for the `puppet.dsc` module.

## Known Limitations

Currently, because of the way Puppet caches files on agents, use of the legacy [``puppetlabs-dsc``]($LegacyDscForgePage) module is **not** compatible with this or any auto-generated DSC module.
Inclusion of both will lead to pluginsync conflicts.
"@
  }

  End {}
}
