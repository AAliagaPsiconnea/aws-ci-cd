<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class TestController extends Controller
{
    public function index()
    {
        $parametro = env('Prueba_Parametro');
        return response()->json([
            'message' => 'Hola Mundo',
            'parametro' => $parametro
        ]);
    }
}
