# README demo for git-coauthors.nvim
#
# Render from the repo root:
#   vhs demo/git-coauthors.tape
#
# demo/setup.sh builds a throwaway repo in /tmp/git-coauthors-demo whose history has a small team.

Output demo.gif

Require bash
Require git
Require nvim

Set Shell "bash"
Set FontFamily "MonoLisaCode, JetBrainsMono Nerd Font"
Set FontSize 16
Set Width 1000
Set Height 560
Set Padding 16
Set Theme "OneHalfDark"
Set TypingSpeed 70ms
Set CursorBlink false

# Setup: sandbox repo with a staged change, then open the commit message in nvim
Hide
Type "bash demo/setup.sh && source /tmp/git-coauthors-demo/env.sh && cd /tmp/git-coauthors-demo/task-tracker && git commit"
Enter
Wait+Screen@60s /Please enter the commit message/
Sleep 1s
Show

Sleep 800ms

# Write the message
Type "i"
Type "feat: add dark mode support"
Enter
Enter
Type "Paired on this with the team."
Enter
Enter
Sleep 500ms

# First co-author: expand the snippet, then pick a handle
Type "cab"
Sleep 800ms
Enter
Sleep 600ms
Type "@"
Wait+Screen /Priya Sharma/
Sleep 1s
Type "pri"
Sleep 800ms
Enter
Sleep 1s

# Second co-author: browse the list
Enter
Type "cab"
Sleep 800ms
Enter
Sleep 600ms
Type "@"
Wait+Screen /Grace Liu/
Sleep 800ms
Down@500ms 2
Sleep 500ms
Enter
Sleep 600ms
Escape

# Hold on the result before looping
Sleep 3s
