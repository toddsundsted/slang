== form_for do |f|
  == f.text_input :hello
  input type="submit"

div
  == form_for do |f|
    == f.text_input :hello
    input type="submit"

div == form_for do |f|
  == f.text_input :hello
  input type="submit"
