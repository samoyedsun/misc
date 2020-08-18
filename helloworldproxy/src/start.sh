composer install -vv
cat .env.example > .env
php artisan key:generate
composer update
exec php artisan serve --host=0.0.0.0 --port=8000
