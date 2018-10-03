/**
 * Created by Ivan Basenko on 05.09.2018.
 */

public with sharing class CheckRecursive {
    private static boolean run = true;

    public static boolean runOnce() {

        if (run) {

            run = false;

            return true;

        } else {

            return run;

        }

    }

}