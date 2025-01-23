#!/bin/bash

# Function to handle menu selection
select_option() {
    # Initialize variables
    local selected=0
    local options=("$@")
    
    # Hide cursor
    tput civis

    # Function to print menu
    print_menu() {
        local idx=0
        echo "Select commit type:"
        for item in "${options[@]}"; do
            if [ $idx -eq $selected ]; then
                echo "❯ $item"
            else
                echo "  $item"
            fi
            ((idx++))
        done
    }

    # Clear screen helper
    clear_menu() {
        printf "\033[%dA" $((${#options[@]} + 1)) # move cursor up
        printf "\033[J" # clear from cursor to end of screen
    }

    # Print initial menu
    print_menu

    # Handle key input
    while true; do
        read -rsn1 key # get 1 character
        case "$key" in
            $'\x1B') # ESC sequence
                read -rsn2 key
                case "$key" in
                    "[A") # Up arrow
                        if [ $selected -gt 0 ]; then
                            ((selected--))
                            clear_menu
                            print_menu
                        fi
                        ;;
                    "[B") # Down arrow
                        if [ $selected -lt $((${#options[@]}-1)) ]; then
                            ((selected++))
                            clear_menu
                            print_menu
                        fi
                        ;;
                esac
                ;;
            "") # Enter key
                tput cnorm # Show cursor
                return $selected
                ;;
        esac
    done
}

# Add all files to git staging
git add -A

# Array of valid commit types
commit_types=("feat" "fix" "chore" "docs" "style" "refactor" "perf" "test" "build" "ci" "revert")

# Show menu and get selection
select_option "${commit_types[@]}"
selected_type="${commit_types[$?]}"

echo -e "\nSelected type: $selected_type"

# Get commit message
while true; do
    read -p "Enter commit description: " description
    if [ ! -z "$description" ]; then
        break
    else
        echo "Description cannot be empty. Please try again."
    fi
done

# Construct the full commit message
commit_message="$selected_type: $description"

# Show the final message and confirm
echo -e "\nFinal commit message:"
echo "$commit_message"
read -p "Proceed with this commit message? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Commit cancelled."
    git reset # Unstage all files
    exit 1
fi

# Try to commit with the constructed message
if ! git commit -m "$commit_message"; then
    echo "Commit failed. Unstaging all files."
    git reset # Unstage all files
    exit 1
fi

# Ask if user wants to push
echo "Do you want to push the changes? (y/N)"
read should_push

if [[ "$should_push" =~ ^[Yy]$ ]]; then
    git push
    echo "Changes pushed successfully!"
else
    echo "Changes committed but not pushed. You can push later using 'git push'"
fi 