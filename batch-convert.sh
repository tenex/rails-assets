mkdir -p "out"

echo "Searching $1"


for pkg in $(bower search $1 | awk '{print $1}' | tail +3); do
  pkg=$(echo $pkg | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
  printf $pkg

  code=$(curl -XPOST http://localhost:9292/convert.json -d name=$pkg -w "%{http_code}" -o out/$pkg.json 2> /dev/null)
  if [ $code = "200" ]; then
    echo " - OK"
  else
    echo " - ERROR"
  fi;
done
