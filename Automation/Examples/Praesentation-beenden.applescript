tell application "PresentInk"
    stop preview
    stop connection
    set drawing enabled to false
    hide annotations
    hide drawer
    read status
end tell
