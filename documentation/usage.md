# Usage

## Security Tips

* Always use recursion counts to break infinite recusion
* Ensure that iteration over `CHOICE` elements cannot loop forever
* Whenever you do arithmetic with externally-supplied data, look carefully for values that are susceptible to buffer underflows, such as `T.min` and `T.max`, where `T` is any integral type.