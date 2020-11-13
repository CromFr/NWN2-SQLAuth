
# Authentication system for Neverwinter Nights 2

## Installation

- Copy the `pw_auth_inc.nss` and `gui_pw_auth.nss` scripts into your module
- It is **strongly** recommended to use Skywing xp_bugfix NWNX4 plugin, in order to encrypt traffic between the client and server, preventing the password to be sent in plain text.
- Modify your module OnPCLoad script by adding these two lines:
    + At the top of the file: `#include "pw_auth_inc"`
    + After `void main(){`:  `PWAuthOnPCLoad();`
- Rebuild all scripts