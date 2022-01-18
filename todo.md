## TODO List

- Add support for first time deploy (when the function and alias do not exist yet) 
    - set alias version to $LATEST
    ? this probably has to use awscli to detect first time function deploy
- Add support for canary deployment
    - do not update alias version yet
    - add weighted version pointing to the new version with rollout
        ? this probably has to be done outside of terraform using awscli