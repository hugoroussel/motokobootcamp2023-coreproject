# Motoko Boot Camp 2023 Core Project

This is the core project for the Motoko Boot Camp 2023.

Canisters IDs:

DAO = 7mmib-yqaaa-aaaap-qa5la-cai
=> https://7fpd5-oyaaa-aaaap-qa5kq-cai.ic0.app/

=> https://6gdk3-2aaaa-aaaap-qa5ma-cai.raw.ic0.app/
Webpage = 6gdk3-2aaaa-aaaap-qa5ma-cai
Assets = 7fpd5-oyaaa-aaaap-qa5kq-cai

## todo last day

### Requirements
How to blackhole canister?

### Web App improvements

=> Create a new page for each proposal
=> Where can I see the webpage canister? => https://6gdk3-2aaaa-aaaap-qa5ma-cai.ic0.app/
=> Add confirmations, loading screens etc. 

### For Neuron follow Neuron

Each Neuron has two additional fields 
=> Followers, List of Neurons that Follow this Neuron
=> Followed does the current Neuron follows anyone

When adding a new follower we need to insure that the graph stays acyclic. 
For this we need to check that neww followers and subfollowers are equal to the current "Followed" neuron. 

=> Add a new page to see all the neurons + buttons to follow, unfollow, etc.