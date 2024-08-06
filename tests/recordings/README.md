# Test Double Recordings

Testing the examples typically takes a long time and tends to have false negatives relatively often, mostly due to timeout errors.

The point of testing the examples is not to test that we can connect to the servers. We have other test points for that. Hence, we insert a “test double” while testing the examples that keeps recordings of previous interactions with the servers and just replays the responses.

This directory contains those recordings.

## Generating Recordings

To generate or re-generate recordings (e.g., after changing an example, or making relevant software changes), open [`texampleTests.m`](../texampleTests.m) and in `setUpAndTearDowns`, change `capture = false;` to `capture = true;`. Then, run the test points relevant to the example(s) in question, and change `capture` back to `false`.

