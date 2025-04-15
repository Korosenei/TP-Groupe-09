
from django.shortcuts import render, redirect
from .forms import ContactForm
from .models import Contact

# Create your views here.

def index(request):
    if request.method == 'POST':
        form = ContactForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('index')
    else:
        form = ContactForm()

    contacts = Contact.objects.all()
    return render(request, 'index.html', {'form': form, 'contacts': contacts})
