# Suspended due to Bazel being too buggy.
# There is a D rules repository, but @bazel_tools//tools/build_defs
# must contain the D package. I don't know how to add it 
# (if that is even possible), so I am just skipping this for now.
#
# It makes sense to just wait for Bazel to be on Version 1.0.0 first,
# anyway.
#
# https://github.com/bazelbuild/rules_d
http_archive(
    name = "io_bazel_rules_d",
    url = "http://bazel-mirror.storage.googleapis.com/github.com/bazelbuild/rules_d/archive/0.0.1.tar.gz",
    sha256 = "6f83ecd38c94a8ff5a68593b9352d08c2bf618ea8f87917c367681625e2bc04e",
    strip_prefix = "rules_d-0.0.1",
)
load("@io_bazel_rules_d//d:d.bzl", "d_repositories")

d_repositories()