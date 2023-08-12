# Building UtilityBelt.Service / UtilityBelt.Scripting

* Download the repositories
* Build Scripting
* In Service add a local NuGet repo pointing to the build folder of Scripting ("Release", should contain a .nupkg)
  * Options > NuGet Package Manager > Package Sources
  * Green plus to add, with name/source:
    * UtilityBelt.Scripting
    * <your projects dir>\utilitybelt.scripting\bin\Release
* Make sure Service is using the local repo.  In the NuGet package manager for the solution:
  * Include prereleases
  * Set "Package source: " to "all" from "nuget.org"
* After building Service you can run the installer and install to ubservice/bin/Releases/net48/ so Decal is loading directly from your build



# Releasing UB Service/Scripting

so releasing is a bit of a thing… if you make a scripting change, you push that to a branch and get it merged to master, and then you need to do a release.  then you go back to service and update to latest nuget release of scripting, and then push service changes

i’ve been thinking about making it able to ref other gitlab builds, but right now you have to stick to public nuget packages or build fails





# ToDo

you can define a module that can be imported, add awaitable actions, etc

https://discord.com/channels/548626271492636675/639939469960544260/1104504933786587219



* Eating input
  * https://gitlab.com/utilitybelt/utilitybelt.service/-/blob/master/Views/HudManager.cs?ref_type=heads#L233
  * https://gitlab.com/utilitybelt/utilitybelt.service/-/blob/master/UBService.cs?ref_type=heads#L258
  * "Here's how you would forward that to scripts" https://gitlab.com/utilitybelt/utilitybelt.service/-/blob/master/UBService.cs?ref_type=heads#L394
* How to access UI elements
  * title###id
* RegexOptions?