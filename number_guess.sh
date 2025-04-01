#!/bin/bash

# Set up database connection
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Function to get user information
get_user_info() {
  # Prompt for username
  echo -e "\nEnter your username:"
  read USERNAME
  
  # Check if the username exists in the database
  USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")
  
  # If user exists
  if [[ -n $USER_INFO ]]; then
    # Parse the user info
    echo "$USER_INFO" | while IFS='|' read GAMES_PLAYED BEST_GAME
    do
      echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    done
  else
    # If this is a new user
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    # Insert new user into database
    INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  fi
}

# Function to play the game
play_game() {
  NUMBER_OF_GUESSES=0
  GUESSED=false
  
  echo "Guess the secret number between 1 and 1000:"
  
  while [[ $GUESSED == false ]]; do
    read GUESS
    
    # Check if input is an integer
    if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
      continue
    fi
    
    # Increment number of guesses
    ((NUMBER_OF_GUESSES++))
    
    # Check the guess against the secret number
    if [[ $GUESS -eq $SECRET_NUMBER ]]; then
      GUESSED=true
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      echo "It's lower than that, guess again:"
    else
      echo "It's higher than that, guess again:"
    fi
  done
  
  # Update user stats in the database
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
  NEW_GAMES_PLAYED=$(($GAMES_PLAYED + 1))
  
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")
  
  # If this is the first game or if this game is better than the best game
  if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
    UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME'")
  else
    UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE username='$USERNAME'")
  fi
}

# Main program execution
get_user_info
play_game