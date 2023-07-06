# FaucetEnv
Network namespace based environment for [Faucet](https://github.com/OscarCornish/Faucet) (Covert Communications)

This environment allows for the Faucet framework to be tested locally, This is the only scenario the framework has been tested under.

## Requirements
* Julia 1.8 or higher
* libpcap-dev
* tcpreplay
* alacritty (optional - but will require changes to automation scripts)

## Building and Tearing down the environment (Namespaces)

`./CreateEnv` to create env
`./Teardown` to tear it down

## Running the framework

```bash

cd FaucetEnv

sudo bash Test (payload size)

```

This will spawn a window to precompile the project, then two more, the sender and the receiver.

These windows are alacritty terminals by default but can be changed in the `Test` script.

## Testing the framework with a warden

```bash

cd FaucetEnv

sudo bash Commblock

```

This defaults the size of the payload and the delay before blocking communication.
