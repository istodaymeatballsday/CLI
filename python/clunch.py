#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function  # print python2
from datetime import datetime
from datetime import timedelta
from threading import Thread

import xml.etree.ElementTree as ET
import locale
import json
import sys
import re
import six

if six.PY2:  # python2
    from Queue import Queue
    import urllib2
    import httplib
elif six.PY3:  # python3
    from queue import Queue
    import urllib.request
    import urllib.error as urllib2  # urllib2.HTTPError
    import http.client as httplib  # httplib.HTTPException

restaurants = [["Expressen", '3d519481-1667-4cad-d2a3'],
               ["Kårrestaurangen", '21f31565-5c2b-4b47-d2a1'],
               ["Linsen", 'b672efaf-032a-4bb8-d2a5'],
               ["S.M.A.K", '3ac68e11-bcee-425e-d2a8'],
               ["J.A. Pripps", 'http://intern.chalmerskonferens.se/'
                'view/restaurant/j-a-pripps-pub-cafe/RSS%20Feed.rss']]


def main():
    set_locale("sv_SE.utf-8")
    menus = get_menus()
    print_data(menus)


def get_menus():
    menus = {}
    queue = build_queue()

    for i in range(queue.qsize()):
        thread = Thread(target=get_menus_thread,
                        args=(queue, menus))
        thread.daemon = True
        thread.start()

    queue.join()

    return menus


def build_queue():
    queue = Queue()
    num_of_days = get_param()
    num_of_restaurants = len(restaurants)

    for restaurant in range(num_of_restaurants):
        queue.put((num_of_days, restaurant))

    return queue


def get_menus_thread(queue, menus):
    while not queue.empty():
        q = queue.get()
        data = get_menu(q[1], q[0])
        r = restaurants[q[1]][0]

        if r == const.PRIPPS:
            menu = parse_pripps_menu(data, q[0])
        else:
            menu = parse_menu(data)

        map_data(menus, menu, q[1])
        queue.task_done()


def get_menu(restaurant, num_of_days):
    url = get_url(restaurant, num_of_days)

    try:
        if six.PY2:
            return urllib2.urlopen(url).read()
        elif six.PY3:
            return urllib.request.urlopen(url).read().decode('utf-8')

    except urllib2.HTTPError as e:
        print("HTTPError: {}".format(e.code))

    except urllib2.URLError as e:
        print("URLError: {}".format(e.reason))

    except httplib.HTTPException as e:
        print("HTTPException: {}".format(e))

    except Exception as e:
        print("Exception: {}".format(e))


def get_url(restaurant, num_of_days):
    r = restaurants[restaurant][0]

    if r == const.PRIPPS:
        return restaurants[restaurant][1]
    else:
        start_date, end_date = get_dates(num_of_days)

        return api.API_URL(
            restaurants[restaurant][1],
            start_date,
            end_date)


def parse_menu(data):
    rawdata = json.loads(data)
    menu = []
    for i in rawdata:
        menu.append(format_date(i['startDate']))
        menu.append(i['displayNames'][0]['dishDisplayName'])

    return menu


def parse_pripps_menu(data, num_of_days):
    item = parse_xml(data)
    menu = []
    start_date, end_date = get_dates(num_of_days)

    for title in item:
        date = title.find("title").text[-10:]

        for description in title:
            for table in description:
                for tr in table:
                    for td in tr:
                        dish = tr.findall("td")[1].text

                        for b in td:
                            dish_type = b.text

                            if date_in_range(date,
                                             start_date,
                                             end_date):
                                append_data(menu,
                                            date,
                                            dish,
                                            dish_type)
    return menu


def parse_xml(data):
    root = ET.fromstring(data)

    return root.findall('channel/item')


def append_data(manu, date, dish, dish_type):
    manu.append(date)
    manu.append(dish + style.DIM +
                " (" + dish_type + ")" + style.DEFAULT)


def date_in_range(date, start_date, end_date):
    return start_date <= date <= end_date


def map_data(menus, data, restaurant):
    num_of_restaurants = len(restaurants)
    length = len(data)

    for i in range(0, length, 2):

        date = data[i]
        dish = data[i+1]

        if date in menus:
            menus[date][restaurant].append(dish)
        else:
            disharr = [[] for i in range(num_of_restaurants)]
            disharr[restaurant].append(dish)
            menus[date] = disharr


def get_param():
    try:
        p = sys.argv[1:][0]
        i = int(p)

        return i if i >= 0 else 0

    except IndexError:
        return 0

    except ValueError:
        return 0


def get_dates(num_of_days):
    today = datetime.today()
    end_date = (today + timedelta(days=num_of_days)).strftime('%Y-%m-%d')
    start_date = today.strftime('%Y-%m-%d')
    return start_date, end_date


def format_date(date):
    return datetime.strptime(
        date[:-3], '%m/%d/%Y %H:%M:%S').strftime('%Y-%m-%d')


def set_locale(code):
    locale.setlocale(locale.LC_ALL, code)


def print_data(menus):
    if not menus:
        print(const.NO_DATA)
        quit()

    for key in sorted(menus):
        print()
        print_date(key)

        for restaurant, menu in enumerate(menus[key]):
            print_restaurant(menu, restaurant)

            for dish in menu:
                print_element(dish)
    print()


def print_date(date):
    print(style.BOLD + style.GREEN + datetime.strptime(
        date, '%Y-%m-%d').strftime('%a') + style.DEFAULT)


def print_restaurant(menu, restaurant):
    print(style.BLUE + restaurants[restaurant][0] + style.DEFAULT)
    if not menu:
        print(const.DOT() + style.DIM + const.NO_MENU + style.DEFAULT)


def print_element(dish):
    ingredient = const.BALLS()
    ans = re.search(r'\b' + re.escape(ingredient)
                    + r'\b', dish, re.IGNORECASE)

    index = find_index(ans)
    if index != -1:
        print_match(dish, ingredient, index)
    else:
        print(const.DOT() + dish)


def find_index(reg):
    try:
        return reg.start()
    except AttributeError:
        return -1


def print_match(dish, ingredient, index):
    length = (index+len(ingredient))

    head = dish[0:index]
    body = dish[index:length]
    tail = dish[length:]

    print(const.DOT() + head + style.BLINK +
          body + style.DEFAULT + tail)


class api:
    BASE_URL = \
        'http://carbonateapiprod.azurewebsites.net/' \
        'api/v1/mealprovidingunits/'

    @staticmethod
    def API_URL(restaurant, start_date, end_date):
        return api.BASE_URL + restaurant + \
            '-08d558129279/dishoccurrences?' \
            'startDate=' + start_date + \
            '&endDate=' + end_date


class style:
    DEFAULT = '\033[0m'
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    BOLD = "\033[1m"
    BLINK = '\33[5m'
    DIM = '\033[2m'


class const:
    NO_DATA = "INGEN DATA"
    NO_MENU = "INGEN MENY"
    PRIPPS = "J.A. Pripps"

    @staticmethod
    def DOT():
        # return '· '.decode("utf-8")
        return const.decode('· ')

    @staticmethod
    def BALLS():
        # return 'köttbullar'.decode("utf-8")
        return const.decode('kötbullar')

    @staticmethod
    def decode(string):
        if six.PY2:
            return string.decode("utf-8")
        elif six.PY3:
            return string


if __name__ == "__main__":
    main()
