FILES=conversions.ml Variable.ml Array_And_Tuple.ml Function.ml test_return.ml Test.ml records.ml Type_Base.ml Function_Print.ml unary_operator.ml while_exp.ml for_exp.ml construct_exp.ml csv.ml match.ml
CC=../php_of_ocaml.native

OUTPUT=$(FILES:.ml=.php)

all: $(OUTPUT)

%.cmt:%.ml
	../scripts/extract_cmt.sh $<

%.php:%.cmt
	$(CC) $< -o $@
