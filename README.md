# mastermind_v1

A simple game of Mastermind, using ruby (No GUI).  

(Version 1)

This game is designed only as a single-player game versus the computer, however
the user can choose to be either the code-maker or the code-breaker.  The
current version consists only of a single game, without the option to continue
with multiple games, and does not keep score. Additionally, the game is played
entirely from the console window.  There is no GUI adaptation for the game.

After each guess by the code-breaker, an updated list is displayed, showing all
guesses made so far, and the number of both "Black" and "White" matches
associated with each guess.  "Black" matches indicate a correct number in the
correct position, while a "White" matches indicate a correct number in the
wrong position.

If the computer is the code-maker, the code is determined randomly.

If the computer is the code-breaker, there is a degree of AI involved.  However,
the computer does have an advantage as compared to the user (when code-breaker),
because the computer knows which particular digit has been designated a "Black"
match or a "White" match.  In contrast, when the user is the code-breaker, he
will know if there has been a "Black" or "White" match, but does not know which
specific digit the match pertains to.

A further revision of the game could make the computer AI more realistic by
removing the knowledge of which digit has been marked as "B" or "W", however
this would significantly increase the complexity of the computer class
guess_code method, and was beyond the current necessity for this project.    
