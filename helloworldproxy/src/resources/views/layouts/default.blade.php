<!doctype html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <title>@yield('title', 'helloworld')proxy</title>
        <!-- Fonts -->
        <link href="https://fonts.googleapis.com/css?family=Nunito:200,600" rel="stylesheet" type="text/css">

        <!-- Styles -->
        <link rel="stylesheet" href="{{ mix('css/app.css') }}">
        
    </head>
    <body>
        @include('layouts._header')
        
        <div class="container">
            <div class="offset-md-1 col-md-10">
                @yield('content')
                @include('layouts._footer')
            </div>
        </div>
    </body>

</html>
