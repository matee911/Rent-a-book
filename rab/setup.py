from setuptools import setup, find_packages
import sys, os

version = '0.1'

setup(name='rab',
      version=version,
      description="Rent-a-book",
      long_description="""\
""",
      classifiers=[], # Get strings from http://pypi.python.org/pypi?%3Aaction=list_classifiers
      keywords='rent book',
      author="Mateusz 'matee' Pawlik",
      author_email='matee@matee.net',
      url='',
      license='',
      packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
      include_package_data=True,
      zip_safe=False,
      install_requires=[
          # -*- Extra requirements: -*-
      ],
      entry_points="""
           [paste.paster_create_template]
           rab = rab.rab.FrameworkTemplate
      """,
      )
