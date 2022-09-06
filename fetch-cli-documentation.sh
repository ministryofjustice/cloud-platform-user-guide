#!/bin/sh

tmp_dir=tmp/
cli_doc_dir=source/documentation/reference/cli

rm -rf $tmp_dir
rm -rf $cli_doc_dir
mkdir -p $cli_doc_dir

git clone https://github.com/ministryofjustice/cloud-platform-cli tmp

for f in tmp/doc/*.md; do
  filename=$(basename "$f" .md)
  { echo '---\ntitle: "Cloud Platform CLI documentation"\n---\n\n# <%= current_page.data.title %>\n\n'; cat "$f" | sed -e 's/\.md/\.html/g'; } > "$cli_doc_dir"/"$filename".html.md.erb
done

mv "$cli_doc_dir"/cloud-platform.html.md.erb "$cli_doc_dir"/index.html.md.erb

rm -rf $tmp_dir
