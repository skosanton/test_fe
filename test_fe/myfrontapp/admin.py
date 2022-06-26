from django.contrib import admin
from myfrontapp.models import Post
from myfrontapp.models import Comment


admin.site.register(Post)
admin.site.register(Comment)