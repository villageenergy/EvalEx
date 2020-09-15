/*
 * Copyright 2012-2020 Udo Klimaschewski
 *
 * http://about.me/udo.klimaschewski
 * http://UdoJava.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:eval_ex/abstract_function.dart';
import 'package:eval_ex/built_ins.dart';
import 'package:eval_ex/expression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("testCustomOperator", () {
    Expression e = new Expression("2.1234 >> 2");

    e.addOperator(OperatorImpl(">>", 30, true, fEval: (v1, v2) {
      return Decimal.parse(pow(10, v2.toInt()).toString()) * v1;
    }));

    expect(e.eval().toString(), "212.34");
  });

  test("testCustomFunction", () {
    Expression e = new Expression("2 * average(12,4,8)");

    e.addFunc(AbstractFuncImpl("average", 3, fEval: (params) {
      Decimal sum = params[0] + params[1] + params[2];
      return sum / Decimal.fromInt(3);
    }));

    expect(e.eval().toString(), "16");
  });

  test("testCustomFunctionInstanceClass", () {
    Expression e = new Expression("2 * average(12,4,8)");

    e.addFunc(FunctionImpl("average", 3, fEval: (params) {
      Decimal sum = params[0] + params[1] + params[2];
      return sum / Decimal.fromInt(3);
    }));

    expect(e.eval().toString(), "16");
  });

  test("testCustomFunctionVariableParameters", () {
    Expression e = new Expression("2 * average(12,4,8,2,9)");
    e.addFunc(AbstractFuncImpl("average", -1, fEval: (params) {
      Decimal sum = Decimal.zero;
      for (Decimal param in params) {
        sum = sum + param;
      }
      return sum / Decimal.fromInt(params.length);
    }));

    expect(e.eval().toString(), "14");
  });

  test("testCustomFunctionVariableParametersInstanceClass", () {
    Expression e = new Expression("2 * average(12,4,8,2,9)");
    e.addFunc(FunctionImpl("average", -1, fEval: (params) {
      Decimal sum = Decimal.zero;
      for (Decimal param in params) {
        sum = sum + param;
      }
      return sum / Decimal.fromInt(params.length);
    }));

    expect(e.eval().toString(), "14");
  });

  test("testCustomFunctionStringParameters", () {
    Expression e = new Expression("STREQ(\"test\", \"test2\")");
    e.addLazyFunction(LazyFunctionImpl("STREQ", 2, fEval: (params) {
      if (params[0].getString() == params[1].getString()) {
        return LazyNumberImpl(eval: () => Decimal.zero, getString: () => "0");
      }

      return LazyNumberImpl(eval: () => Decimal.one, getString: () => "1");
    }));

    expect(e.eval().toString(), "1");
  });

  test("testCustomFunctionBoolean", () {
    Expression e = new Expression("STREQ(\"test\", \"test2\")");
    e.addLazyFunction(
        LazyFunctionImpl("STREQ", 2, booleanFunction: true, fEval: (params) {
          if (params[0].getString() == params[1].getString()) {
            return LazyNumberImpl(
                eval: () => Decimal.zero, getString: () => "0");
          }

          return LazyNumberImpl(eval: () => Decimal.one, getString: () => "1");
        }));

    expect(e.eval().toString(), "1");
    expect(e.isBoolean(), true);
  });

  test("testUnary", () {
    Expression exp = new Expression("~23");

    exp.addOperator(UnaryOperatorImpl("~", 60, false, fEval: (d) {
      return d;
    }));

    expect(exp.eval().toString(), "23");
  });

  test("testCustomOperatorAnd", () {
    Expression e = new Expression("1 == 1 AND 2 == 2");

    e.addOperator(OperatorImpl(
        "AND", Expression.operatorPrecedenceAnd, false, booleanOperator: true, fEval: (
        v1, v2) {
        bool b1 = v1.compareTo(Decimal.zero) != 0;

        if(!b1) {
          return Decimal.zero;
        }

        bool b2 = v2.compareTo(Decimal.zero) != 0;
        return b2 ? Decimal.one : Decimal.zero;
    }));

    expect(e.eval().toString(), "1");
  });
}

class AbstractFuncImpl extends AbstractFunction {
  Function(List<Decimal>) fEval;

  AbstractFuncImpl(String name, int numParams,
      {bool booleanFunction = false, this.fEval})
      : super(name, numParams, booleanFunction: booleanFunction);

  @override
  Decimal eval(List<Decimal> parameters) {
    return this.fEval(parameters);
  }
}
