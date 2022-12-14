# 2D Matlab RPY code: README

Supplementary Matlab/Octave code to ['Methods for suspensions of passive and active filaments'](https://arxiv.org/abs/1903.12609), 2019, by SF Schoeller, AK Townsend, TA Westwood & EE Keaveny.

## 1. Whom do I talk to?
* Rory

## 2. What does this code do?
This code demonstrates the use of the method described in "How Do Microorganisms Swim?" in simulating filaments swimming in an infinite domain.

It uses the 'EJBb' version of Broyden's method (Algorithm 2 in the paper) with a reduced 'robot arm' system of nonlinear equations. For the hydrodynamic solver, it uses the RPY tensors.

## 3. How do I run it?
To use, just run `main.m` in Matlab.
