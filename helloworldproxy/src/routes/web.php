<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () { return view('index'); })->name('home');
Route::get('/help', function () { return view('index'); })->name('help');
Route::get('/about', function () { return view('index'); })->name('about');

Route::get('_create_', 'UsersController@create')->name('_create_');
Route::get('_delete_', 'UsersController@delete')->name('_delete_');
Route::post('/details', 'UsersController@details')->name('details');
Route::post('/confirm', 'UsersController@confirm')->name('confirm');
