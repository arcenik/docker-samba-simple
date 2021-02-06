#! /bin/bash -xe

b=$(git branch --show-current)

git push github ${b}
git push origin ${b}
