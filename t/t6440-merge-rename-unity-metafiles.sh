#!/bin/sh

test_description='Merge-recursive merging renames Unity .meta files'
GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

modify () {
	sed -e "$1" <"$2" >"$2.x" &&
	mv "$2.x" "$2"
}

test_expect_success 'setup' '

    cat >.gitattributes <<-\EOF &&
	*.meta unitymetafile
	EOF

    git add .gitattributes &&
	git commit -m "set attribute on .meta files" &&

	cat >A.meta <<-\EOF &&
	fileFormatVersion: 2
    guid: 16fa2ad734f422245b86558310973ad1
    folderAsset: yes
    DefaultImporter:
      externalObjects: {}
      userData: 
      assetBundleName: 
      assetBundleVariant: 
	EOF

	cat >M.meta <<-\EOF &&
	fileFormatVersion: 2
    guid: e31c136ab48c1194184380e435f3936d
	EOF

	git add A.meta M.meta &&
	git commit -m "initial has A and M" &&
	git branch white &&
	git branch red &&
	git branch blue &&
	git branch yellow &&
	git branch change &&
	git branch change+rename &&
	git branch different &&

	sed -e "/userData: /s/userData:/userData: main changes a line/" <A.meta >A+ &&
	mv A+ A.meta &&
	git commit -a -m "main updates A" &&

	git checkout yellow &&
	rm -f M.meta &&
	git commit -a -m "yellow removes M" &&

	git checkout white &&
	sed -e "/userData: /s/userData:/userData: white changes a line/" <A.meta >B.meta &&
	sed -e "/fileFormatVersion/s/.*/fileFormatVersion: 3/" <M.meta >N.meta &&
	rm -f A.meta M.meta &&
	git update-index --add --remove A.meta B.meta M.meta N.meta &&
	git commit -m "white renames A->B, M->N" &&

	git checkout red &&
	sed -e "/userData: /s/userData:/userData: red changes a line/" <A.meta >B.meta &&
	sed -e "/fileFormatVersion/s/.*/fileFormatVersion: 3/" <M.meta >N.meta &&
	rm -f A.meta M.meta &&
	git update-index --add --remove A.meta B.meta M.meta N.meta &&
	git commit -m "red renames A->B, M->N" &&

	git checkout blue &&
	sed -e "/userData: /s/userData:/userData: blue changes a line/" <A.meta >C.meta &&
	sed -e "/fileFormatVersion/s/.*/fileFormatVersion: 3/" <M.meta >N.meta &&
	rm -f A.meta M.meta &&
	git update-index --add --remove A.meta C.meta M.meta N.meta &&
	git commit -m "blue renames A->C, M->N" &&

	git checkout change &&
	sed -e "/userData: /s/userData:/userData: changed line/" <A.meta >A+ &&
	mv A+ A.meta &&
	git commit -q -a -m "changed" &&

	git checkout change+rename &&
	sed -e "/userData: /s/userData:/userData: changed line/" <A.meta >B.meta &&
	rm A.meta &&
	git update-index --add B.meta &&
	git commit -q -a -m "changed and renamed" &&

	git checkout different &&
	rm -f A.meta M.meta &&
	git update-index --remove A.meta M.meta &&
	git commit -m "different removes A, M" &&
	cat >B.meta <<-\EOF &&
	fileFormatVersion: 2
    guid: 26fa2ad734f422245b86558310973ad1
    folderAsset: yes
    DefaultImporter:
      externalObjects: {}
      userData: 
      assetBundleName: 
      assetBundleVariant: 
	EOF

	cat >N.meta <<-\EOF &&
	fileFormatVersion: 2
    guid: f31c136ab48c1194184380e435f3936d
	EOF

	git update-index --add B.meta N.meta &&
	git commit -m "different introduces B.meta, N.meta" &&

	git checkout main
'

# Ensure that the modified A.meta does not get merged with B.meta
# because they have different GUIDs
test_expect_success 'file with different GUID not considered a rename candidate' \
'
	git show-branch &&
	test_expect_code 0 git pull --no-rebase . different &&
	git ls-files -s &&
	test_stdout_line_count = 0 git ls-files -u &&
	sed -ne "/userData/{
	p
	q
	}" B.meta | grep -v main
'

test_done
