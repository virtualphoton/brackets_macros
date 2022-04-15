# Brackets autocomplete macro

The macro helps to work with brackets, resembling behaviour of such 
IDEs as PyCharm. It will be shown on example of `(`, but user defines the set of brackets, 
or similar objects, such as quotation marks or dollar signs
- typing `(` will also create `)`
- selecting `text` and pressing `(` will wrap it - `(text)` and `text` will be selected (hence, it
  can be wrapped with multiple brackets) (currently, it works quite slowly on long strings)
- typing `(` and then pressing `Backspace` will erase both `(` and `)` (if any other key was pressed/the mouse was moved
  this behaviour won't appear)
- typing `)`, when there's already `)` right after the cursor and there's an unmatched
`(` before cursor (on the same line) will cause cursor to move left instead of typing `)` (though,
   this yet doesn't work for cases when opening and closing "brackets" are the same - e.g. pressing
  `$` will always create `$$`)
  
List of brackets can be set in `main.ahk`:

- `brackets_start` - dictionary with keys - hotkeys, values - array of length 3: `opening_bracket, closing_bracket,
  [data_about_hotkey]`.
  `data_about_hotkey` is dictionary with fields that can change behaviour for current hotkey (actually, there were more
  than 1, but they turned out to be redundant):
  - `ru_char` - char printed if keyboard layout is Russian (since some characters on it differ from the english layout)
- `brackets_end` - to skip closing brackets instead of printing them (as described earlier).
Same parameters as in previous: unclosed `opening_bracket` - will be searched.

To run script, run `main.ahk`. It will compute files containing lists of hotkeys and run
another script for them - `auxiliary.ahk`. If new shortcuts are added/deleted you should relaunch `main.ahk`.
If only their parameters are changed, you can reload just `auxiliary.ahk` 

To suspend/unsuspend script, press `Ctrl+J`
