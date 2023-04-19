### Todo

* Find what is crashing.  Ask trevis about the debug build

* Missing properties toggle

  * Might require enum list to be added to Lua  definitions
  * May do some checks on object type to see what properties ever exist
    * For each object ID
      * Find a list of properties used
      * Average / sdev for highlighting?
      * Min/Max for input ranges

* Sort lists/other ImGui table goodness

  * ```lua
    local sortSpecs = IM.TableGetSortSpecs()
    if sortSpecs.SpecsDirty then print("Dirty") sortSpecs.SpecsDirty = false end
    ```

* Show empty tabs?

* Server-side

  * Batching support
  * Vitals/Attributes?
  * Make sure properties are getting changed / changes sent to clients.
  * Option to force save?

* Check for WorldObject accessible

  * ~~Sorrrta done?~~
  * ~~Send reassess before applying changes~~

* ~~Reset changes~~

* ~~Case-insensitive filter~~



### Ref

* [Patterns](http://www.lua.org/manual/5.1/manual.html#5.4.1)

