#!/bin/bash
Stophead='(?:Breakpoint hit|Step completed)'
Jword='[^.(#$]+'
Method='(?:lambda$[^$]+$)?[^$(]+'
Class="$Jword(?:\\.$Jword)*(?=(?:\\.$Method\()|\\$)"
Row='[0-9]+'
Breakpoint="($Stophead: [^,]+, ($Class)[^,]+, line=($Row).+)"

Level='\[[0-9]+\]'
WhereClass="$Jword(?:\\.$Jword)*(?=(?:\\.$Method )|\\$)"
Where="($Level ($WhereClass)[^ ]+ \([^:]+:($Row)\))"


ssed -R "s/$Breakpoint/-\1-\2-\3-/p" /tmp/jdb.txt | ssed -R "s/$Where/-\1-\2-\3-/" 
