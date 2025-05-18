from django.shortcuts import render
from django.http import HttpResponse, HttpResponseNotAllowed
import logging

logger = logging.getLogger('backend')

# Create your views here.
def hello_view(request):
  extra_data = {
    'user': str(request.user) if request.user.is_authenticated else "Anonymous",
  }

  if request.method != "GET":
    logger.error(
          f"Request started: {request.method} {request.path}",
          extra=extra_data
      )
    return HttpResponseNotAllowed()
  
  logger.info(
        f"Request started: {request.method} {request.path}",
        extra=extra_data
    )
  return HttpResponse("Hello, World!")
