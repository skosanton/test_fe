from django.shortcuts import render
from django.http import HttpResponse
from .models import Post
# Create your views here.

def index(request):
    my_dict = {'insert_me':"Hi there"}
    return render(request,'myfrontapp/index.html',context=my_dict)

...
def individual_post(request):
#    return HttpResponse('Hi, this is where an individual post will be.')
    recent_post = Post.objects.get(id__exact=1 )
    return HttpResponse(recent_post.title + ': ' + recent_post.content)


""" #MONGODB CONNECTION
from project.utils import get_db_handle
db_handle, mongo_client = get_db_handle(DATABASE_NAME, 127.0.0.1, 27017, USERNAME, PASSWORD) """