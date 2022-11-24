(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)
 
--int push int
-- + push +
-- s push s
-- e evaluate 
--    1.+ pop + and pop 2 int followed push a+b
--    2.s pop s and swap 2 value followed
-- d display
-- x stop 

class Stack {

   new_stack : Stack;

   operator : String;

   pre : Stack;

   data() : String {operator};

   rest() : Stack {pre};

   init(i : String, r : Stack) : Stack
   {
      {
         operator <- i;
         pre <- r;
         self;
      }
   };

   push(i : String ) : Stack {
      {
         new_stack <- new Stack;
         new_stack.init(i,self);
      }
   };

   pop() : String {
         operator
   };

};

class Stack_command {
   
   io : IO <- new IO;
   num1 : String;
   num2 : String;
   atoi : A2I <- new A2I;
   x1 : Int;
   x2 : Int;

   pluscommand(s:Stack):Stack{
      {
         s <- s.rest();
         num1 <- s.pop();
         s <- s.rest();
         num2 <- s.pop();
         s <- s.rest();
         x1 <- atoi.a2i(num1);
         x2 <- atoi.a2i(num2);
         x1 <- x2+x1;
         s <- s.push(atoi.i2a(x1));
         s;
      }
   };

   swapcommand(s:Stack):Stack{
      {
         s <- s.rest();
         num1 <- s.pop();
         s <- s.rest();
         num2 <- s.pop();
         s <- s.rest();
         s <- s.push(num1);
         s <- s.push(num2);
         s;
      }
   };

   display(s : Stack) : Object{
      
         while(not(s.data() = "")) loop
         {
            io.out_string(s.data());
            io.out_string("\n");
            s <- s.rest();
         } 
         pool
      
   };

};


class Main inherits IO {

   s : Stack;
   command : Stack_command;
   str : String;
   main() : Object {
      {
         s <- new Stack;
         command <- new Stack_command;
         out_string(">");
         while (not ((str <- in_string()) = "x")) loop
         {
            if (str = "d") then
            {
               command.display(s);
            }
            else if (str = "e") then
            {
               if (s.data() = "+")then
               {
                  s <- command.pluscommand(s);
               }
               else
               {
                  s <- command.swapcommand(s);
               }
               fi;
            }
            else 
            {
               s <- s.push(str);
            }
            fi fi;
            out_string(">");
         }
         pool;
   }
   };
};
